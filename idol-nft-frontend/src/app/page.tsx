import Header from '../components/layout/Header';
import CardList from '../components/cards/CardList';
import MarketList from '../components/market/MarketList';

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      <main className="container mx-auto px-6 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-800">探索偶像卡片</h1>
          <p className="mt-2 text-gray-600">发现、收集和交易独特的偶像NFT卡片</p>
        </div>
        <CardList />
        <h2 className="text-3xl font-bold mt-8">市场</h2>
        <MarketList />
      </main>
    </div>
  );
}
