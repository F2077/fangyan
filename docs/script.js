/* 方言字报 · 展示数据（curate 自 references/方言灵魂.json + 民间习俗.md §1）
   落地页是策展产物；方言增删时手动同步此处即可（或后续改为从 JSON 生成）。 */
const DIALECTS = [
  { name:'北京话', region:'华北·京',   folk:'京剧 · 相声',   color:'#8B2C2C', sig:'吃了么您内？',     soul:['局气','甭','倍儿'] },
  { name:'天津话', region:'华北·津',   folk:'相声 · 时调',   color:'#2E5A88', sig:'吃了嘛您？',       soul:['哏儿','倍儿','介'] },
  { name:'东北话', region:'东北·关外', folk:'二人转 · 秧歌', color:'#C7611E', sig:'嘎哈呢？',         soul:['整','贼','嘎哈'] },
  { name:'山东话', region:'华北·齐鲁', folk:'快书 · 吕剧',   color:'#3F5E4A', sig:'老师儿，吃了么？', soul:['老师儿','杠','贼'] },
  { name:'陕西话', region:'西北·关中', folk:'秦腔 · 老腔',   color:'#A9763C', sig:'咥面去！',         soul:['咥','谝','嘹'] },
  { name:'河南话', region:'中原',     folk:'豫剧 · 坠子',   color:'#B8923A', sig:'中！',             soul:['中','恁','嘞'] },
  { name:'云南话', region:'西南·云',   folk:'山歌 · 火把',   color:'#D45D3A', sig:'给是嫩个？',       soul:['噶','给是','整'] },
  { name:'成都话', region:'西南·蜀',   folk:'川剧 · 清音',   color:'#4A6B5D', sig:'安逸，巴适得板！', soul:['安逸','巴适','莫得'] },
  { name:'重庆话', region:'西南·巴',   folk:'号子 · 袍哥',   color:'#6B2B2B', sig:'雄起！',           soul:['雄起','扎起','安逸'] },
  { name:'湖南话', region:'华中·湘',   folk:'花鼓 · 湘剧',   color:'#B23A48', sig:'恰饭哒冇？',       soul:['恰','嬲塞','韵味'] },
  { name:'上海话', region:'江南·沪',   folk:'沪剧 · 滑稽',   color:'#5B6B6E', sig:'侬好伐？',         soul:['阿拉','侬','伐'] },
  { name:'粤语',   region:'华南·粤',   folk:'舞狮 · 饮茶',   color:'#2E7D5B', sig:'食咗饭未？',       soul:['唔该','食','嘅'] },
  { name:'闽南话', region:'华南·闽',   folk:'南音 · 拜拜',   color:'#C99A2E', sig:'汝食饭矣未？',     soul:['厝','阮','伊'] },
];

/* 安全 DOM 构造（el, tag, text, cls）—— 不用 innerHTML */
function el(tag, { cls, text } = {}) {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text != null) n.textContent = text;
  return n;
}

function renderTray() {
  const tray = document.getElementById('tray');
  if (!tray) return;
  DIALECTS.forEach((d, i) => {
    const b = el('button', { cls: 'stamp', text: d.name });
    b.style.setProperty('--accent', d.color);
    b.style.setProperty('--tilt', `${(i % 2 ? 1 : -1) * (1 + (i % 3))}deg`);
    b.setAttribute('aria-label', `跳到 ${d.name}`);
    b.addEventListener('click', () => {
      const card = document.getElementById('card-' + i);
      if (card) card.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
    tray.appendChild(b);
  });
}

function renderDeck() {
  const deck = document.getElementById('deck');
  if (!deck) return;
  DIALECTS.forEach((d, i) => {
    const band = el('div', { cls: 'card-band' });
    band.append(el('span', { cls: 'card-name', text: d.name }), el('span', { cls: 'card-region', text: d.region }));

    const chips = el('div', { cls: 'chips' });
    d.soul.forEach(s => chips.appendChild(el('span', { cls: 'chip', text: s })));

    const foot = el('div', { cls: 'card-foot' });
    foot.append(el('span', { cls: 'card-folk', text: d.folk }), el('span', { text: `灵魂词 ${d.soul.length}` }));

    const body = el('div', { cls: 'card-body' });
    body.append(el('p', { cls: 'card-sig', text: d.sig }), chips, foot);

    const card = el('article', { cls: 'card' });
    card.id = 'card-' + i;
    card.style.setProperty('--accent', d.color);
    card.style.setProperty('--i', i);
    card.append(band, body);
    deck.appendChild(card);
  });
}

/* 报头「今日一言」：轮换展示一方之言 */
function dailyLine() {
  const node = document.getElementById('daily');
  if (!node) return;
  let cur = -1;
  const tick = () => {
    let j;
    do { j = Math.floor(Math.random() * DIALECTS.length); } while (j === cur && DIALECTS.length > 1);
    cur = j;
    const d = DIALECTS[j];
    node.replaceChildren(document.createTextNode(`今日一言 · ${d.name}：`), el('em', { text: d.sig }));
  };
  tick();
  if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
    setInterval(tick, 4200);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  renderTray();
  renderDeck();
  dailyLine();
});
