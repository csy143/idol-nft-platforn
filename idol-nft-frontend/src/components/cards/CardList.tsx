"use client";
import { useState, useEffect } from 'react';
import { useContract } from '../../hooks/useContract';
import { CONTRACT_ADDRESSES, ABIS } from '../../utils/constants';
import { ethers } from 'ethers';

interface Card {
  id: string;
  uri: string;
  cardType: number;
  seriesId: string;
  name: string;
  image: string;
}

interface Listing {
  tokenId: string;
  seller: string;
  price: string;
}

export default function CardList() {
  const [cards, setCards] = useState<Card[]>([]);
  const [loading, setLoading] = useState(true);
  const contract = useContract(CONTRACT_ADDRESSES.IDOL_CARD, ABIS.IDOL_CARD);

  useEffect(() => {
    const fetchCards = async () => {
      if (contract) {
        try {
          setLoading(true);
          const totalSupply = await contract.totalSupply();
          const cardPromises = [];

          for (let i = 0; i < totalSupply.toNumber(); i++) {
            cardPromises.push(contract.tokenByIndex(i).then(async (tokenId: string) => {
              const cardDetails = await contract.getCardDetails(tokenId);
              const metadata = await fetch(cardDetails.uri).then(res => res.json());
              
              return {
                id: tokenId.toString(),
                uri: cardDetails.uri,
                cardType: cardDetails.cardType,
                seriesId: cardDetails.seriesId.toString(),
                name: metadata.name,
                image: metadata.image
              };
            }));
          }

          const cardData = await Promise.all(cardPromises);
          setCards(cardData);
        } catch (error) {
          console.error('获取卡片失败:', error);
        } finally {
          setLoading(false);
        }
      }
    };

    fetchCards();
  }, [contract]);

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6">
      {cards.map(card => (
        <div key={card.id} className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
          <div className="relative pb-[100%]">
            <img 
              src={card.image} 
              alt={card.name}
              className="absolute top-0 left-0 w-full h-full object-cover"
            />
          </div>
          <div className="p-4">
            <h3 className="text-lg font-semibold text-gray-800">{card.name}</h3>
            <div className="mt-2 flex justify-between items-center">
              <span className="text-sm text-gray-500">系列 #{card.seriesId}</span>
              <span className={`px-2 py-1 rounded-full text-xs ${
                card.cardType === 0 ? 'bg-gray-100 text-gray-600' :
                card.cardType === 1 ? 'bg-blue-100 text-blue-600' :
                'bg-purple-100 text-purple-600'
              }`}>
                {card.cardType === 0 ? '普通' : card.cardType === 1 ? '稀有' : '超稀有'}
              </span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
} 