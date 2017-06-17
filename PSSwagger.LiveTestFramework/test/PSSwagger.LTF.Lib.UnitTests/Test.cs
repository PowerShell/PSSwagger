using Xunit;
using Xunit.Abstractions;
using System;
using System.Threading.Tasks;

public class Test
{
    [Fact]
    public async Task Method()
    {
        PSSwagger.LTF.Lib.Class1 test = new PSSwagger.LTF.Lib.Class1();
        Console.WriteLine("Hello world");
    }
}