"use client";
import { useState, useEffect } from 'react';
import { useContract } from '../../hooks/useContract';
import { CONTRACT_ADDRESSES, ABIS } from '../../utils/constants';
import { ethers } from 'ethers';

interface Listing {
  tokenId: string;
  seller: string;
  price: string;
}

export default function MarketList() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const marketContract = useContract(CONTRACT_ADDRESSES.IDOL_MARKET, ABIS.IDOL_MARKET);

  useEffect(() => {
    const fetchListings = async () => {
      if (marketContract) {
        try {
          const listedEvents = await marketContract.queryFilter(marketContract.filters.Listed());
          const activeListings = await Promise.all(
            listedEvents.map(async (event) => {
              const listing = await marketContract.listings(event.args.tokenId);
              if (listing.isActive) {
                return {
                  tokenId: event.args.tokenId.toString(),
                  seller: listing.seller,
                  price: ethers.utils.formatEther(listing.price),
                };
              }
              return null;
            })
          );

          setListings(activeListings.filter(Boolean));
        } catch (error) {
          console.error('获取市场列表失败:', error);
        } finally {
          setLoading(false);
        }
      }
    };

    fetchListings();
  }, [marketContract]);

  if (loading) {
    return <div>加载中...</div>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6">
      {listings.map(listing => (
        <div key={listing.tokenId} className="bg-white rounded-xl shadow-lg overflow-hidden">
          <div className="p-4">
            <h3 className="text-lg font-semibold">Token ID: {listing.tokenId}</h3>
            <p className="text-gray-600">卖家: {listing.seller}</p>
            <p className="text-gray-600">价格: {listing.price} ETH</p>
          </div>
        </div>
      ))}
    </div>
  );
} 