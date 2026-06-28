import { Card, CardHeader, CardBody, Stat, Chip } from 'gym-bro-web';

export const Text = () => (
  <Card>
    <CardHeader title="Yesterday" />
    <CardBody>
      Crushed Push Day. PR'd bench at 100kg × 5. Felt easier than last week.
    </CardBody>
  </Card>
);

export const Stats = () => (
  <Card>
    <CardHeader title="This week" />
    <CardBody>
      <div style={{ display: 'flex', gap: 32 }}>
        <Stat label="Sessions" value="3" />
        <Stat label="Volume" value="14,200" unit="kg" />
        <Stat label="Avg RPE" value="7.8" />
      </div>
    </CardBody>
  </Card>
);

export const Chips = () => (
  <Card>
    <CardHeader title="Ingredients" subtitle="extracted from photo" />
    <CardBody>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        <Chip>4 eggs</Chip>
        <Chip>olive oil</Chip>
        <Chip>rolled oats</Chip>
        <Chip tone="muted">salt (trace)</Chip>
      </div>
    </CardBody>
  </Card>
);
