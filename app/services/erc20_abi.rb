module Erc20Abi
  # 完整 BEP-20 / ERC-20 标准 ABI（读写全含）
  STANDARD = [
    # ===== 元数据 =====
    { "constant" => true, "inputs" => [], "name" => "name",
      "outputs" => [{ "name" => "", "type" => "string" }],
      "stateMutability" => "view", "type" => "function" },
    { "constant" => true, "inputs" => [], "name" => "symbol",
      "outputs" => [{ "name" => "", "type" => "string" }],
      "stateMutability" => "view", "type" => "function" },
    { "constant" => true, "inputs" => [], "name" => "decimals",
      "outputs" => [{ "name" => "", "type" => "uint8" }],
      "stateMutability" => "view", "type" => "function" },
    { "constant" => true, "inputs" => [], "name" => "totalSupply",
      "outputs" => [{ "name" => "", "type" => "uint256" }],
      "stateMutability" => "view", "type" => "function" },

    # ===== 余额 =====
    { "constant" => true,
      "inputs" => [{ "name" => "account", "type" => "address" }],
      "name" => "balanceOf",
      "outputs" => [{ "name" => "", "type" => "uint256" }],
      "stateMutability" => "view", "type" => "function" },

    # ===== 转账 =====
    { "constant" => false,
      "inputs" => [
        { "name" => "to", "type" => "address" },
        { "name" => "amount", "type" => "uint256" }
      ],
      "name" => "transfer",
      "outputs" => [{ "name" => "", "type" => "bool" }],
      "stateMutability" => "nonpayable", "type" => "function" },

    { "constant" => false,
      "inputs" => [
        { "name" => "from", "type" => "address" },
        { "name" => "to", "type" => "address" },
        { "name" => "amount", "type" => "uint256" }
      ],
      "name" => "transferFrom",
      "outputs" => [{ "name" => "", "type" => "bool" }],
      "stateMutability" => "nonpayable", "type" => "function" },

    # ===== 授权 =====
    { "constant" => false,
      "inputs" => [
        { "name" => "spender", "type" => "address" },
        { "name" => "amount", "type" => "uint256" }
      ],
      "name" => "approve",
      "outputs" => [{ "name" => "", "type" => "bool" }],
      "stateMutability" => "nonpayable", "type" => "function" },

    { "constant" => true,
      "inputs" => [
        { "name" => "owner", "type" => "address" },
        { "name" => "spender", "type" => "address" }
      ],
      "name" => "allowance",
      "outputs" => [{ "name" => "", "type" => "uint256" }],
      "stateMutability" => "view", "type" => "function" },

    # ===== 事件 =====
    { "anonymous" => false,
      "inputs" => [
        { "indexed" => true,  "name" => "from",  "type" => "address" },
        { "indexed" => true,  "name" => "to",    "type" => "address" },
        { "indexed" => false, "name" => "value", "type" => "uint256" }
      ],
      "name" => "Transfer", "type" => "event" },

    { "anonymous" => false,
      "inputs" => [
        { "indexed" => true,  "name" => "owner",   "type" => "address" },
        { "indexed" => true,  "name" => "spender", "type" => "address" },
        { "indexed" => false, "name" => "value",   "type" => "uint256" }
      ],
      "name" => "Approval", "type" => "event" }
  ].freeze

  # 兼容别名：早期代码可能引用 METADATA，避免 NameError
  METADATA = STANDARD

  # 非常规：name() / symbol() 返回 bytes32 的老合约
  BYTES32_METADATA = [
    { "constant" => true, "inputs" => [], "name" => "name",
      "outputs" => [{ "name" => "", "type" => "bytes32" }],
      "stateMutability" => "view", "type" => "function" },
    { "constant" => true, "inputs" => [], "name" => "symbol",
      "outputs" => [{ "name" => "", "type" => "bytes32" }],
      "stateMutability" => "view", "type" => "function" },
    { "constant" => true, "inputs" => [], "name" => "decimals",
      "outputs" => [{ "name" => "", "type" => "uint8" }],
      "stateMutability" => "view", "type" => "function" }
  ].freeze

  # 统一入口：优先用用户上传的自定义 ABI，否则用标准 ABI
  def self.for(token)
    if token.abi.present?
      JSON.parse(token.abi)
    else
      STANDARD
    end
  end
end
