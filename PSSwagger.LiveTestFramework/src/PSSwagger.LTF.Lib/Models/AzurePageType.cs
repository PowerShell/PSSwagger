// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.
namespace PSSwagger.LTF.Lib.Models
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Linq;
    using System.Reflection;

    /// <summary>
    /// Wraps a Page object used by Azure REST.
    /// </summary>
    public class AzurePageType
    {
        private Type pageType;
        private Type itemsListType;
        private PropertyInfo nextPageLinkInfo;
        private PropertyInfo itemsInfo;

        /// <summary>
        /// Gets or sets the next link for the page.
        /// </summary>
        public string NextLink { get; set; }

        /// <summary>
        /// Gets the list of page items.
        /// </summary>
        public IList<object> Items { get; private set; }

        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="genericPageType">Type of page.</param>
        /// <param name="itemsType">Type of items in page.</param>
        /// <param name="nextLinkPropertyName">Case-insensitive name of the property containing next link.</param>
        /// <param name="itemsPropertyName">Case-insensitive name of the property containing the list of page items.</param>
        public AzurePageType(Type genericPageType, Type itemsType)
        {
            this.pageType = genericPageType.MakeGenericType(itemsType);
            this.itemsListType = typeof(List<>).MakeGenericType(itemsType);
            this.Items = new List<object>();
            this.nextPageLinkInfo = this.pageType.GetProperties().Where(pi => pi.Name.Equals("NextPageLink", StringComparison.OrdinalIgnoreCase)).Single();
            this.itemsInfo = this.pageType.GetProperties(BindingFlags.NonPublic | BindingFlags.Instance).Where(pi => pi.Name.Equals("Items", StringComparison.OrdinalIgnoreCase)).Single();
        }

        public object GetPage()
        {
            object page = Activator.CreateInstance(this.pageType);
            this.nextPageLinkInfo.SetValue(page, this.NextLink);
            IList pageItems = (IList)Activator.CreateInstance(this.itemsListType);
            foreach (object item in this.Items)
            {
                pageItems.Add(item);
            }

            this.itemsInfo.SetValue(page, pageItems);
            return page;
        }
    }
}