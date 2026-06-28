import { Card, CardHeader, CardBody, CardFooter, Button } from 'gym-bro-web';

export const Plain = () => (
  <Card>
    <CardHeader title="Push Day" />
    <CardBody>Bench · OHP · Tricep Pushdown</CardBody>
    <CardFooter>last performed 3 days ago · 12 sets · 42 min</CardFooter>
  </Card>
);

export const WithAction = () => (
  <Card>
    <CardHeader title="Confirm meal log" />
    <CardBody>
      4 eggs · olive oil · 1 cup rice · chicken breast
    </CardBody>
    <CardFooter>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
        <span>1,985 cal · 108g protein</span>
        <Button size="sm" variant="primary">Log</Button>
      </div>
    </CardFooter>
  </Card>
);
