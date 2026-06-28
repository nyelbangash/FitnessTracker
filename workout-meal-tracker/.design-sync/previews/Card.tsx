import { Card, CardHeader, CardBody, CardFooter, Button, Stat } from 'gym-bro-web';

export const Basic = () => (
  <Card>
    <CardBody>
      <div className="num text-2xl">1,820 cal</div>
      <div className="text-sm text-muted mt-1">consumed today</div>
    </CardBody>
  </Card>
);

export const WithHeader = () => (
  <Card>
    <CardHeader title="Today's macros" subtitle="2 meals logged" />
    <CardBody>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        <Stat label="Cal" value="1,820" />
        <Stat label="P" value="112" unit="g" />
        <Stat label="C" value="142" unit="g" />
        <Stat label="F" value="64" unit="g" />
      </div>
    </CardBody>
  </Card>
);

export const Full = () => (
  <Card>
    <CardHeader
      title="Push Day"
      subtitle="last performed 3 days ago"
      action={<Button size="sm" variant="primary">Start</Button>}
    />
    <CardBody>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <div className="text-sm">Bench Press · 4 × 5</div>
        <div className="text-sm">Overhead Press · 4 × 6</div>
        <div className="text-sm">Tricep Pushdown · 3 × 10</div>
      </div>
    </CardBody>
    <CardFooter>3 exercises · 11 sets · ~38 min</CardFooter>
  </Card>
);

export const Raised = () => (
  <Card raised>
    <CardBody>
      <div className="text-sm text-muted">Raised variant — same content surface, slightly darker.</div>
    </CardBody>
  </Card>
);
