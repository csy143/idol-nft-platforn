// 从合约编译输出中获取 ABI
import IdolCardABI from '../contracts/IdolCard.json';
import IdolMarketABI from '../contracts/IdolMarket.json';
import CompanyRegistryABI from '../contracts/CompanyRegistry.json';


// 实际使用时切换到这些
export const CONTRACT_ADDRESSES = {
  IDOL_CARD: "0xAda0dADD1D9cd4a74425392b1e062C0b26ba743a",
  IDOL_MARKET:"0x2C93273f7C441fD52cd2366E3D8F0317D172589D",
  COMPANY_REGISTRY: "0x6d565Fa89C81FCc39b0Af0430eBB93BCdF776165"
};

export const ABIS = {
  IDOL_CARD: IdolCardABI,
  IDOL_MARKET: IdolMarketABI,
  COMPANY_REGISTRY: CompanyRegistryABI,
}; 