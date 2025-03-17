import Header from '../../components/layout/Header';
import MarketList from '../../components/market/MarketList';

export default function Market() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      <main className="container mx-auto px-6 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-800">NFT 市场</h1>
          <p className="mt-2 text-gray-600">浏览并购买偶像卡片</p>
        </div>
        <MarketList />
      </main>
    </div>
  );
} 