import { Button } from 'gym-bro-web';

export const Primary = () => (
  <Button variant="primary">Save meal</Button>
);

export const Default = () => (
  <Button>Cancel</Button>
);

export const Ghost = () => (
  <Button variant="ghost">Edit</Button>
);

export const Danger = () => (
  <Button variant="danger">Delete workout</Button>
);

export const Sizes = () => (
  <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
    <Button size="sm">sm</Button>
    <Button size="md">md</Button>
    <Button size="lg">lg</Button>
    <Button size="xl" variant="primary">Complete set</Button>
  </div>
);

export const Disabled = () => (
  <Button variant="primary" disabled>Logging…</Button>
);
