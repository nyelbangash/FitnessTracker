import { Chip } from 'gym-bro-web';

export const Default = () => (
  <Chip>4 eggs</Chip>
);

export const Muted = () => (
  <Chip tone="muted">low confidence</Chip>
);

export const Accent = () => (
  <Chip tone="accent">PR</Chip>
);

export const Clickable = () => (
  <Chip onClick={() => {}}>Push Day</Chip>
);

export const Row = () => (
  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
    <Chip>chicken breast</Chip>
    <Chip>rolled oats</Chip>
    <Chip>olive oil</Chip>
    <Chip tone="muted">tomato (estimated)</Chip>
    <Chip tone="accent">favorite</Chip>
  </div>
);
