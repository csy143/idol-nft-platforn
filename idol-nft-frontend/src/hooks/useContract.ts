import { ethers } from 'ethers';
import { useState, useEffect } from 'react';

export function useContract(contractAddress: string, abi: any) {
  const [contract, setContract] = useState<ethers.Contract | null>(null);

  useEffect(() => {
    if (typeof window.ethereum !== 'undefined') {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(contractAddress, abi, signer);
      setContract(contract);
    }
  }, [contractAddress, abi]);

  return contract;
} 