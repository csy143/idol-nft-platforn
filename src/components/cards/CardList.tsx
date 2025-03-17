"use client";
import { useState, useEffect } from 'react';
import { useContract } from '../../hooks/useContract';
import { CONTRACT_ADDRESSES, ABIS } from '../../utils/constants';

interface Card {
  id: string;
  uri: string;
  name: string;
  image: string;
}

export default function CardList() {
  const [cards, setCards] = useState<Card[]>([]);
  const [loading, setLoading] = useState(true);
  const contract = useContract(CONTRACT_ADDRESSES.IDOL_CARD, ABIS.IDOL_CARD);

  useEffect(() => {
    const fetchCards = async () => {
      if (contract) {
        try {
          const totalSupply = await contract.totalSupply();
          const cardPromises = [];

          for (let i = 0; i < totalSupply.toNumber(); i++) {
            cardPromises.push(contract.tokenByIndex(i).then(async (tokenId: string) => {
              const cardDetails = await contract.getCardDetails(tokenId);
              const metadata = await fetch(cardDetails.uri).then(res => res.json());
              
              return {
                id: tokenId.toString(),
                uri: cardDetails.uri,
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
    return <div>加载中...</div>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6">
      {cards.map(card => (
        <div key={card.id} className="bg-white rounded-xl shadow-lg overflow-hidden">
          <img src={card.image} alt={card.name} className="w-full h-48 object-cover" />
          <div className="p-4">
            <h3 className="text-lg font-semibold">{card.name}</h3>
          </div>
        </div>
      ))}
    </div>
  );
} 