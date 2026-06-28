import { Stat } from 'gym-bro-web';

export const Basic = () => (
  <Stat label="Volume" value="12,400" unit="kg" />
);

export const WithHint = () => (
  <Stat label="Avg RPE" value="7.8" hint="up from 7.4 last week" />
);

export const Centered = () => (
  <Stat label="Streak" value="14" unit="days" align="center" />
);

export const Row = () => (
  <div style={{ display: 'flex', gap: 32, flexWrap: 'wrap' }}>
    <Stat label="Volume" value="12,400" unit="kg" />
    <Stat label="Avg RPE" value="7.8" />
    <Stat label="Streak" value="14" unit="days" />
    <Stat label="PRs" value="3" hint="this month" />
  </div>
);
