import { describe, expect, it, vi, beforeEach } from "vitest";

// Mocking trait contract function calls
const mockTokenTraitCall = vi.fn();

const tokenTrait = {
  call: mockTokenTraitCall,
};

describe("Token Trait Tests", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should verify if an asset ID is valid", async () => {
    const assetId = 123;
    // Mock the response to simulate a valid asset ID
    mockTokenTraitCall.mockResolvedValueOnce({ ok: true, result: true });

    const result = await tokenTrait.call("is-valid-asset-id", [assetId]);

    expect(result.ok).toBe(true);
    expect(result.result).toBe(true);
  });

  it("should retrieve balance for a principal and asset ID", async () => {
    const userPrincipal = "ST1USERADDRESS1";
    const assetId = 123;

    // Mock the response with a balance of 1000
    mockTokenTraitCall.mockResolvedValueOnce({ ok: true, result: { balance: 1000 } });

    const result = await tokenTrait.call("get-balance", [userPrincipal, assetId]);

    expect(result.ok).toBe(true);
    expect(result.result.balance).toBe(1000);
  });

  it("should approve a principal to transfer a specific amount of an asset", async () => {
    const spender = "ST1SPENDERADDRESS";
    const assetId = 123;
    const amount = 500;

    // Mock the approval response
    mockTokenTraitCall.mockResolvedValueOnce({ ok: true, result: true });

    const result = await tokenTrait.call("approve", [spender, assetId, amount]);

    expect(result.ok).toBe(true);
    expect(result.result).toBe(true);
  });

  it("should allow transfer of tokens from one principal to another", async () => {
    const from = "ST1FROMADDRESS";
    const to = "ST1TOADDRESS";
    const assetId = 123;
    const amount = 250;

    // Mock the transfer response
    mockTokenTraitCall.mockResolvedValueOnce({ ok: true, result: true });

    const result = await tokenTrait.call("transfer-from", [from, to, assetId, amount]);

    expect(result.ok).toBe(true);
    expect(result.result).toBe(true);
  });

  it("should return an error for an invalid asset ID check", async () => {
    const invalidAssetId = 999;

    // Mock the response to simulate an invalid asset ID
    mockTokenTraitCall.mockResolvedValueOnce({ ok: false, error: "invalid asset id" });

    const result = await tokenTrait.call("is-valid-asset-id", [invalidAssetId]);

    expect(result.ok).toBe(false);
    expect(result.error).toBe("invalid asset id");
  });
});
