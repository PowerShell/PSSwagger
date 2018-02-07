// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.

// PSSwaggerUtility Module
namespace $($LocalizedData.CSharpNamespace)
{
	using Microsoft.Rest;
    using System;
    using System.Net.Http;
    using System.Net.Http.Headers;
    using System.Runtime.CompilerServices;
    using System.Runtime.InteropServices;
    using System.Security;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
	
	public class PSBasicAuthenticationEx : ServiceClientCredentials
    {
        public string UserName { get; set; }
        public SecureString Password { get; set; }
        public PSBasicAuthenticationEx(string userName, SecureString password)
        {
            this.UserName = userName;
            this.Password = password;
        }

        public override async Task ProcessHttpRequestAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            await Task.Run(() => ProcessHttpRequest(request), cancellationToken);
        }

        private void ProcessHttpRequest(HttpRequestMessage request)
        {
            int passwordLength = this.Password.Length;
            int userNameLength = this.UserName.Length;
            int totalCredsLength = passwordLength + userNameLength + 1;
            int base64size = Base64Encoder.PredictSize(totalCredsLength);
            byte[] userNameBytes = Encoding.UTF8.GetBytes(this.UserName);
            // This array ensures we clean up the string concatenation of "username:password"
            byte[] clientCredsArr = new byte[totalCredsLength];
            // And here we need to clean up the base64 encoded string
            // 3 bytes == 4 characters, + padding
            // totalCredsLength is the number of bytes we'll eventually encode
            char[] base64string = new char[base64size];
            GCHandle byteHandle = new GCHandle();
            GCHandle strHandle = new GCHandle();
            // Ensure the insecure client cred string and the GC handle are cleaned up
            RuntimeHelpers.ExecuteCodeWithGuaranteedCleanup(delegate
            {
                // This block pins the insecure client cred string, converts the SecureString to the insecure password, frees the unpinned string, then generates the basic auth headers
                RuntimeHelpers.PrepareConstrainedRegions();
                try { }
                finally
                {
                    byteHandle = GCHandle.Alloc(clientCredsArr, GCHandleType.Pinned);
                    strHandle = GCHandle.Alloc(base64string, GCHandleType.Pinned);
                }

                
                IntPtr pBstr = IntPtr.Zero;
                // Ensure bBstr is properly cleaned up
                RuntimeHelpers.ExecuteCodeWithGuaranteedCleanup(delegate
                    {
                        RuntimeHelpers.PrepareConstrainedRegions();
                        try { }
                        finally
                        {
                            pBstr = Marshal.SecureStringToBSTR(this.Password);
                        }

                        unsafe
                        {
                            char* pTempPassword = (char*)pBstr;
                            byte* pClientCreds = (byte*)byteHandle.AddrOfPinnedObject();
                            Encoding.UTF8.GetBytes(pTempPassword, passwordLength, pClientCreds + userNameLength + 1, passwordLength);
                            for (int i = 0; i < userNameLength; i++)
                            {
                                pClientCreds[i] = userNameBytes[i];
                            }
                            pClientCreds[userNameLength] = (byte)':';
                            Base64Encoder.Encode(clientCredsArr, base64string);
                        }
                    },
                    delegate
                    {
                        if (pBstr != IntPtr.Zero)
                        {
                            Marshal.ZeroFreeBSTR(pBstr);
                        }
                    }, null);

                // Not using BasicAuthenticationCredentials here because: 1) async, 2) need to have the handle to the pinned base64 encoded string
                // NOTE: URL safe encoding?
                request.Headers.Authorization = new AuthenticationHeaderValue("Basic", new string(base64string));
            }, delegate
            {
                if (byteHandle.IsAllocated)
                {
                    unsafe
                    {
                        byte* pClientCreds = (byte*)byteHandle.AddrOfPinnedObject();
                        for (int i = 0; i < totalCredsLength; i++)
                        {
                            pClientCreds[i] = 0;
                        }

                        byteHandle.Free();

                        char* pBase64String = (char*)strHandle.AddrOfPinnedObject();
                        for (int i = 0; i < base64size; i++)
                        {
                            pBase64String[i] = '\0';
                        }

                        strHandle.Free();
                    }
                }
            }, null);
        }
    }

     public static class Base64Encoder
    {
        private const byte ls6mask = 0x3F;
        private const byte ls4mask = 0x0F;
        private const byte ls2mask = 0x03;
        private const byte ms6mask = 0xFC;
        private const byte ms4mask = 0xF0;
        private const byte ms2mask = 0xC0;
        private static char[] base64encoding = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
                                                 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
                                                 '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/' };
        private static Func<byte?, byte?, byte>[] base64encoder =
        {
            (b1, b2) =>
            {
                // MS6 of b2
                return (byte)((b2 & ms6mask) >> 2);
            },
            (b1, b2) =>
            {
                // LS2 of b1 + MS4 of b2
                return (byte)((byte)((b1 & ls2mask) << 4) | (byte)((b2 & ms4mask) >> 4));
            },
            (b1, b2) =>
            {
                // LS4 of b1 + MS2 of b2
                return (byte)((byte)((b1 & ls4mask) << 2) | (byte)((b2 & ms2mask) >> 6));
            },
            (b1, b2) =>
            {
                // LS6 of b1
                return (byte)(b1 & ls6mask);
            }
        };

        public static void Encode(byte[] bytesToEncode, char[] charsToCopyOut)
        {
            int charOutIndex = 0;
            byte[] currentEncodingBuffer = new byte[2];
            int indexToAddByte;
            if (BitConverter.IsLittleEndian)
            {
                currentEncodingBuffer[1] = 0;
                indexToAddByte = 0;
            }
            else
            {
                currentEncodingBuffer[0] = 0;
                indexToAddByte = 1;
            }

            int encodingActionIndex = 0;
            byte? lastByte = null;
            for (int i = 0; i < bytesToEncode.Length; i++)
            {
                if (charOutIndex >= charsToCopyOut.Length)
                {
                    throw new Exception("Out char buffer is not big enough for base64 encoded string.");
                }

                charsToCopyOut[charOutIndex++] = GetChar(base64encoder[encodingActionIndex](lastByte, bytesToEncode[i]),
                    currentEncodingBuffer, indexToAddByte);
                if (encodingActionIndex == bytesToEncode.Length - 1)
                {
                    // Last step resets the next lastByte to null
                    lastByte = null;
                }
                else
                {
                    lastByte = bytesToEncode[i];
                }

                encodingActionIndex = (encodingActionIndex + 1) % base64encoder.Length;

                // If the next action is the last one, run it now and reset lastByte
                if (encodingActionIndex == base64encoder.Length - 1)
                {
                    if (charOutIndex >= charsToCopyOut.Length)
                    {
                        throw new Exception("Out char buffer is not big enough for base64 encoded string.");
                    }

                    charsToCopyOut[charOutIndex++] = GetChar(base64encoder[encodingActionIndex](bytesToEncode[i], null),
                        currentEncodingBuffer, indexToAddByte);
                    encodingActionIndex = (encodingActionIndex + 1) % base64encoder.Length;
                    lastByte = null;
                }
                else
                {
                    lastByte = bytesToEncode[i];
                }
            }

            // One more phase to run on the last byte
            if (encodingActionIndex != 0)
            {
                if (charOutIndex >= charsToCopyOut.Length)
                {
                    throw new Exception("Out char buffer is not big enough for base64 encoded string.");
                }

                charsToCopyOut[charOutIndex++] = GetChar(base64encoder[encodingActionIndex](lastByte, 0),
                    currentEncodingBuffer, indexToAddByte);
            }

            int charsLeft = charOutIndex % 4;
            if (charsLeft != 0)
            {
                int padding = 4 - charsLeft;
                while (padding-- > 0)
                {
                    charsToCopyOut[charOutIndex++] = '=';
                }
            }
        }

        public static int PredictSize(int numberOfBytes)
        {
            return (int)(4 * Math.Ceiling((double)numberOfBytes / 3));
        }

        private static char GetChar(byte b, byte[] buffer, int index)
        {
            buffer[index] = b;
            return base64encoding[BitConverter.ToInt16(buffer, 0)];
        }
    }
}
