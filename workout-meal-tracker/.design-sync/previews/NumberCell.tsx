import { NumberCell } from 'gym-bro-web';

export const Reps = () => (
  <NumberCell label="Reps" value={8} onChange={() => {}} />
);

export const Weight = () => (
  <NumberCell label="Weight" value={102.5} onChange={() => {}} suffix="kg" step={2.5} />
);

export const Trio = () => (
  <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
    <NumberCell label="Reps" value={5} onChange={() => {}} />
    <NumberCell label="Weight" value={100} onChange={() => {}} suffix="kg" step={2.5} />
    <NumberCell label="RPE" value={8} onChange={() => {}} step={0.5} max={10} />
  </div>
);
