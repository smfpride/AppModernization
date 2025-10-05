using eShopLegacyMVC.Models;
using System;

namespace eShopLegacyMVC.Models
{
    public class CatalogItemHiLoGenerator
    {
        private int sequenceId = 0;
        private readonly object sequenceLock = new object();

        public int GetNextSequenceValue(CatalogDBContext db)
        {
            lock (sequenceLock)
            {
                sequenceId++;
                return sequenceId;
            }
        }
    }
}