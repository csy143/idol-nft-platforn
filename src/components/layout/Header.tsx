"use client";
import { useState } from 'react';
import Link from 'next/link';
import { useWallet } from '../../hooks/useWallet';

export default function Header() {
  const { account, connectWallet } = useWallet();

  return (
    <header className="bg-white shadow-lg">
      <nav className="container mx-auto px-6 py-4">
        <div className="flex justify-between items-center">
          <div className="flex items-center">
            <Link href="/" className="text-2xl font-bold text-purple-600">
              Idol NFT
            </Link>
            <div className="hidden md:flex ml-10 space-x-8">
              <Link href="/market" className="text-gray-600 hover:text-purple-600">
                市场
              </Link>
              <Link href="/auction" className="text-gray-600 hover:text-purple-600">
                拍卖
              </Link>
              <Link href="/my-cards" className="text-gray-600 hover:text-purple-600">
                我的卡片
              </Link>
              <Link href="/company" className="text-gray-600 hover:text-purple-600">
                经纪公司
              </Link>
            </div>
          </div>
          
          <div className="flex items-center">
            {account ? (
              <div className="bg-purple-100 px-4 py-2 rounded-full">
                <span className="text-purple-600">{`${account.slice(0, 6)}...${account.slice(-4)}`}</span>
              </div>
            ) : (
              <button
                onClick={connectWallet}
                className="bg-purple-600 text-white px-6 py-2 rounded-full hover:bg-purple-700 transition-colors"
              >
                连接钱包
              </button>
            )}
          </div>
        </div>
      </nav>
    </header>
  );
} 