
/* ============================================================
   二维码弹窗
   ============================================================ */
document.getElementById('qrModal').addEventListener('show.bs.modal', e => {
  const addr = e.relatedTarget.dataset.address;
  if (!addr) return;
  document.getElementById('qrAddress').textContent = addr;

  // 使用 qrcode-generator 生成二维码（纯本地，无外部 API）
  const qr = qrcode(0, 'M');
  qr.addData(addr);
  qr.make();
  // createImgTag(cellSize, margin)
  document.getElementById('qrCodeContainer').innerHTML = qr.createImgTag(5, 8);
});

document.getElementById('copyAddressBtn').addEventListener('click', async () => {
  const text = document.getElementById('qrAddress').textContent;
  try {
    await navigator.clipboard.writeText(text);
    const btn = document.getElementById('copyAddressBtn');
    const orig = btn.textContent;
    btn.textContent = '✓ 已复制';
    setTimeout(() => btn.textContent = orig, 1500);
  } catch (err) {
    alert('复制失败，请手动选择文本');
  }
});

/* ============================================================
   执行分发：接收地址选择
   ============================================================ */
const recvAll = document.getElementById('recvAll');
const recvBoxes = () => document.querySelectorAll('#recvTable tbody input[type="checkbox"]');

recvAll.addEventListener('change', e => {
  recvBoxes().forEach(c => c.checked = e.target.checked);
  updateSummary();
});

recvBoxes().forEach(c => c.addEventListener('change', updateSummary));

document.getElementById('selectAllBtn').addEventListener('click', () => {
  recvAll.checked = true;
  recvAll.dispatchEvent(new Event('change'));
});

document.getElementById('confirmSelectAll').addEventListener('click', () => {
  // 实际场景下这里会通过 API 拉全量选中
  alert('已选中全部 3 个接收地址（示例）');
  updateSummary();
});

/* ============================================================
   执行分发：金额模式 / 币种联动
   ============================================================ */
document.querySelectorAll('input[name="amtmode"]').forEach(r => r.addEventListener('change', () => {
  const fixed = document.getElementById('amt-fixed').checked;
  document.getElementById('fixedAmtBlock').classList.toggle('d-none', !fixed);
  document.getElementById('randAmtBlock').classList.toggle('d-none', fixed);
  updateSummary();
}));

['fixedAmt', 'randMin', 'randMax'].forEach(id => {
  const el = document.getElementById(id);
  if (el) el.addEventListener('input', updateSummary);
});

document.getElementById('disperseToken').addEventListener('change', e => {
  const unit = e.target.value || 'BNB';
  document.getElementById('unitLabel').textContent = unit;
  document.getElementById('sumUnit').textContent = unit;
  updateSummary();
});

/* ============================================================
   执行分发：汇总计算
   ============================================================ */
function updateSummary() {
  const n = document.querySelectorAll('#recvTable tbody input[type="checkbox"]:checked').length;
  const fixed = document.getElementById('amt-fixed').checked;
  const unit = document.getElementById('disperseToken').value || 'BNB';

  let total = 0;
  let desc = '';

  if (fixed) {
    const amt = parseFloat(document.getElementById('fixedAmt').value) || 0;
    total = n * amt;
    desc = `${amt} ${unit} × ${n} 个地址`;
  } else {
    const min = parseFloat(document.getElementById('randMin').value) || 0;
    const max = parseFloat(document.getElementById('randMax').value) || 0;
    // 随机模式下显示范围
    total = null;
    desc = `随机 ${min}~${max} ${unit} × ${n} 个地址`;
  }

  document.getElementById('selCount').textContent = n;
  document.getElementById('sumCount').textContent = n;
  document.getElementById('sumAmount').textContent = total === null ? '随机' : total.toFixed(4);
  document.getElementById('sumUnit').textContent = unit;

  document.getElementById('disperseExecBtn').dataset.execDesc =
    `${desc}，请输入执行密码。`;
}

/* ============================================================
   执行密码弹窗动态文案
   ============================================================ */
document.getElementById('execPasswordModal').addEventListener('show.bs.modal', e => {
  const t = e.relatedTarget;
  if (t) {
    document.getElementById('execTitle').textContent = t.dataset.execTitle || '确认执行';
    document.getElementById('execDesc').textContent = t.dataset.execDesc || '';
    document.getElementById('execPassword').value = '';
  }
});

document.getElementById('execConfirm').addEventListener('click', () => {
  const pwd = document.getElementById('execPassword').value;
  if (pwd.length < 8) {
    alert('请输入至少 8 位执行密码');
    return;
  }
  alert('已提交执行（示例）');
  bootstrap.Modal.getInstance(document.getElementById('execPasswordModal')).hide();
});

/* ============================================================
   其他按钮（示例占位）
   ============================================================ */
['refreshFromBalanceBtn', 'refreshToBalanceBtn'].forEach(id => {
  document.getElementById(id).addEventListener('click', () => {
    alert('已刷新余额（示例）');
  });
});

/* 初始化 */
updateSummary();
