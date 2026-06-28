import { Bar } from 'gym-bro-web';

export const Half = () => (
  <div style={{ width: 320 }}>
    <Bar value={50} max={100} />
  </div>
);

export const NearFull = () => (
  <div style={{ width: 320 }}>
    <Bar value={92} max={100} />
  </div>
);

export const Overflow = () => (
  <div style={{ width: 320 }}>
    <Bar value={118} max={100} />
  </div>
);

export const Stack = () => (
  <div style={{ width: 320, display: 'flex', flexDirection: 'column', gap: 14 }}>
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
        <span>Calories</span><span className="num">1,820 / 2,200</span>
      </div>
      <Bar value={1820} max={2200} />
    </div>
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
        <span>Protein</span><span className="num">112 / 150 g</span>
      </div>
      <Bar value={112} max={150} />
    </div>
  </div>
);
