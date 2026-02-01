'use client';

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { SquaresPoolABI } from '@/lib/abis/SquaresPool';

export interface YieldInfo {
  principal: bigint;
  aTokenBalance: bigint;
  yield: bigint;
  aaveConfigured: boolean;
}

export function usePoolYieldInfo(poolAddress: `0x${string}` | undefined) {
  const { data, isLoading, refetch } = useReadContract({
    address: poolAddress,
    abi: SquaresPoolABI,
    functionName: 'getYieldInfo',
    query: {
      enabled: !!poolAddress,
    },
  });

  const yieldInfo: YieldInfo | undefined = data
    ? {
        principal: data[0] as bigint,
        aTokenBalance: data[1] as bigint,
        yield: data[2] as bigint,
        aaveConfigured: data[3] as boolean,
      }
    : undefined;

  return {
    yieldInfo,
    isLoading,
    refetch,
  };
}

export function useWithdrawYield(poolAddress: `0x${string}` | undefined) {
  const { writeContract, data: hash, isPending, error, reset } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const withdrawYield = () => {
    if (!poolAddress) return;

    writeContract({
      address: poolAddress,
      abi: SquaresPoolABI,
      functionName: 'withdrawYield',
    });
  };

  return {
    withdrawYield,
    isPending,
    isConfirming,
    isSuccess,
    error,
    reset,
    hash,
  };
}

export function usePoolState(poolAddress: `0x${string}` | undefined) {
  const { data, isLoading } = useReadContract({
    address: poolAddress,
    abi: SquaresPoolABI,
    functionName: 'state',
    query: {
      enabled: !!poolAddress,
    },
  });

  return {
    state: data as number | undefined,
    isLoading,
    isFinished: data === 6, // FINAL_SCORED = 6
  };
}
