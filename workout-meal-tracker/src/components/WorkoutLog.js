import React, { useEffect, useState } from "react";
import {
  Typography,
  List,
  Container,
  Paper,
  Alert,
  Box,
  Divider,
  Grid,
} from "@mui/material";
import { getWorkouts } from "../api";

const WorkoutLog = () => {
  const [workouts, setWorkouts] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchWorkouts = async () => {
      try {
        const workoutsData = await getWorkouts();
        setWorkouts(workoutsData);
      } catch (error) {
        setError("Failed to load workouts. Please try again later.");
      } finally {
        setLoading(false);
      }
    };

    fetchWorkouts();
  }, []);

  if (loading) {
    return (
      <Container maxWidth="md">
        <Typography>Loading workouts...</Typography>
      </Container>
    );
  }

  if (error) {
    return (
      <Container maxWidth="md">
        <Alert severity="error">{error}</Alert>
      </Container>
    );
  }

  return (
    <Container maxWidth="md">
      <Typography variant="h4" align="center" gutterBottom>
        Workout Log
      </Typography>

      {workouts.length === 0 ? (
        <Alert severity="info">No workouts recorded yet.</Alert>
      ) : (
        <List>
          {workouts.map((workout, index) => (
            <Paper key={index} elevation={2} sx={{ mb: 2, p: 2 }}>
              <Grid container spacing={2}>
                <Grid xs={12}>
                  <Typography variant="h6">{workout.workout_name}</Typography>
                  <Typography color="text.secondary" gutterBottom>
                    Date: {workout.date_worked_out} | Duration:{" "}
                    {workout.length_of_workout} minutes
                  </Typography>
                </Grid>

                <Grid xs={12}>
                  <Typography variant="subtitle1" sx={{ mt: 1 }}>
                    Exercises:
                  </Typography>
                  {workout.exercises.map((exercise, idx) => (
                    <Box key={idx} sx={{ ml: 2, my: 1 }}>
                      <Typography>{exercise.exercise_name}</Typography>
                      {exercise.sets.map((set, setIdx) => (
                        <Typography
                          key={setIdx}
                          color="text.secondary"
                          sx={{ ml: 2 }}
                        >
                          Set {setIdx + 1}: {set.reps} reps @ {set.weight}kg
                        </Typography>
                      ))}
                    </Box>
                  ))}
                </Grid>
              </Grid>
              {index < workouts.length - 1 && <Divider sx={{ mt: 2 }} />}
            </Paper>
          ))}
        </List>
      )}
    </Container>
  );
};

export default WorkoutLog;
