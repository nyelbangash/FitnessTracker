// WorkoutLog.js
import React, { useEffect, useState } from "react";
import {
  Typography,
  List,
  ListItem,
  ListItemText,
  Container,
} from "@mui/material";
import { getWorkouts } from "./api";

const WorkoutLog = () => {
  const [workouts, setWorkouts] = useState([]);

  useEffect(() => {
    const fetchWorkouts = async () => {
      try {
        const workoutsData = await getWorkouts();
        setWorkouts(workoutsData);
      } catch (error) {
        // Handle error, e.g., display error message
      }
    };

    fetchWorkouts();
  }, []);

  return (
    <Container maxWidth="sm">
      <Typography variant="h4" align="center" gutterBottom>
        Workout Log
      </Typography>
      <List>
        {workouts.map((workout) => (
          <ListItem key={workout.id}>
            <ListItemText
              primary={workout.workoutName}
              secondary={
                <>
                  <Typography
                    component="span"
                    variant="body2"
                    color="textPrimary"
                  >
                    Date: {workout.date}
                  </Typography>
                  <br />
                  <Typography
                    component="span"
                    variant="body2"
                    color="textPrimary"
                  >
                    Duration: {workout.duration} minutes
                  </Typography>
                </>
              }
            />
          </ListItem>
        ))}
      </List>
    </Container>
  );
};

export default WorkoutLog;
