# 概述

Binance Smart Chain 批量转账与地址管理系统，仅限内部使用

# 说明
- 本地测试主网需要手动切换节点api【services/balance_service.rb】
  - https://bsc-testnet.infura.io/v3/api_key
  - https://bsc-mainnet.infura.io/v3/api_key
- 测试网络的tBNB需要手动更改Token表的token_type字段值为native 
- 测试网络导入bep20需要手动更改Token表的chain_id值
  - 测试网：97
  - 正式网：56（默认）
