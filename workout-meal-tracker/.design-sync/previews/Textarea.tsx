import { Textarea } from 'gym-bro-web';

export const Notes = () => (
  <div style={{ width: 380 }}>
    <Textarea label="Workout notes" rows={3} placeholder="How did it feel?" />
  </div>
);

export const Filled = () => (
  <div style={{ width: 380 }}>
    <Textarea
      label="Meal description"
      rows={3}
      defaultValue="4 eggs with olive oil, glass of OJ, pound of chicken breast, half a cup of instant rice."
    />
  </div>
);
