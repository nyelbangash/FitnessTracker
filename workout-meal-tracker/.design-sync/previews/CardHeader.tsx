import { Card, CardHeader, CardBody, Button } from 'gym-bro-web';

export const TitleOnly = () => (
  <Card>
    <CardHeader title="Today's macros" />
    <CardBody>body content goes here</CardBody>
  </Card>
);

export const WithSubtitle = () => (
  <Card>
    <CardHeader title="Push Day" subtitle="last performed Wednesday" />
    <CardBody>body content</CardBody>
  </Card>
);

export const WithAction = () => (
  <Card>
    <CardHeader
      title="Workout in progress"
      subtitle="Bench Press, set 2 of 4"
      action={<Button size="sm" variant="primary">Resume</Button>}
    />
    <CardBody>body content</CardBody>
  </Card>
);
