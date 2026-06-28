import { Ring } from 'gym-bro-web';

export const Calories = () => (
  <Ring value={1820} max={2200} number={1820} label="CAL" />
);

export const Protein = () => (
  <Ring value={112} max={150} number={112} label="PROTEIN" />
);

export const Overflow = () => (
  <Ring value={185} max={150} number={185} label="PROTEIN" />
);

export const Row = () => (
  <div style={{ display: 'flex', gap: 24, alignItems: 'center' }}>
    <Ring value={1820} max={2200} number={1820} label="CAL" />
    <Ring value={112} max={150} number={112} label="P" />
    <Ring value={210} max={250} number={210} label="C" />
    <Ring value={62} max={70} number={62} label="F" />
  </div>
);

export const Big = () => (
  <Ring value={350} max={500} number={350} label="VOLUME" size={120} stroke={10} />
);
