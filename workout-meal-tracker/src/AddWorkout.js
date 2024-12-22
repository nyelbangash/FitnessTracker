// AddWorkout.js
import React, { useState } from "react";
import {
  TextField,
  Button,
  Container,
  Typography,
  Grid,
  IconButton,
} from "@mui/material";
import { Delete as DeleteIcon } from "@mui/icons-material";
import { addWorkout } from "./api";

const AddWorkout = () => {
  const [workoutName, setWorkoutName] = useState("");
  const [exercises, setExercises] = useState([
    { name: "", sets: "", reps: "", weight: "" },
  ]);
  const [date, setDate] = useState("");
  const [duration, setDuration] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const workoutData = {
        workoutName,
        exercises,
        date,
        duration,
      };
      await addWorkout(workoutData);
      // Clear form fields after successful submission
      setWorkoutName("");
      setExercises([{ name: "", sets: "", reps: "", weight: "" }]);
      setDate("");
      setDuration("");
      // Display success message or update workout log
    } catch (error) {
      // Handle error, e.g., display error message
    }
  };

  const handleExerciseChange = (index, field, value) => {
    const updatedExercises = [...exercises];
    updatedExercises[index][field] = value;
    setExercises(updatedExercises);
  };

  const addExercise = () => {
    setExercises([...exercises, { name: "", sets: "", reps: "", weight: "" }]);
  };

  const removeExercise = (index) => {
    const updatedExercises = exercises.filter((_, i) => i !== index);
    setExercises(updatedExercises);
  };

  return (
    <Container maxWidth="sm">
      <Typography variant="h4" align="center" gutterBottom>
        Add Workout
      </Typography>
      <form onSubmit={handleSubmit}>
        <TextField
          label="Workout Name"
          variant="outlined"
          fullWidth
          margin="normal"
          value={workoutName}
          onChange={(e) => setWorkoutName(e.target.value)}
        />
        <TextField
          label="Date"
          variant="outlined"
          fullWidth
          margin="normal"
          value={date}
          onChange={(e) => setDate(e.target.value)}
        />
        <TextField
          label="Duration (minutes)"
          variant="outlined"
          fullWidth
          margin="normal"
          value={duration}
          onChange={(e) => setDuration(e.target.value)}
        />
        {exercises.map((exercise, index) => (
          <Grid container key={index} spacing={2} alignItems="center">
            <Grid item xs={12} sm={3}>
              <TextField
                label="Exercise Name"
                variant="outlined"
                fullWidth
                value={exercise.name}
                onChange={(e) =>
                  handleExerciseChange(index, "name", e.target.value)
                }
              />
            </Grid>
            <Grid item xs={4} sm={2}>
              <TextField
                label="Sets"
                variant="outlined"
                fullWidth
                value={exercise.sets}
                onChange={(e) =>
                  handleExerciseChange(index, "sets", e.target.value)
                }
              />
            </Grid>
            <Grid item xs={4} sm={2}>
              <TextField
                label="Reps"
                variant="outlined"
                fullWidth
                value={exercise.reps}
                onChange={(e) =>
                  handleExerciseChange(index, "reps", e.target.value)
                }
              />
            </Grid>
            <Grid item xs={4} sm={2}>
              <TextField
                label="Weight"
                variant="outlined"
                fullWidth
                value={exercise.weight}
                onChange={(e) =>
                  handleExerciseChange(index, "weight", e.target.value)
                }
              />
            </Grid>
            <Grid item xs={12} sm={2}>
              <IconButton onClick={() => removeExercise(index)}>
                <DeleteIcon />
              </IconButton>
            </Grid>
          </Grid>
        ))}
        <Button variant="outlined" color="primary" onClick={addExercise}>
          Add Exercise
        </Button>
        <Button
          type="submit"
          variant="contained"
          color="primary"
          fullWidth
          style={{ marginTop: "16px" }}
        >
          Add Workout
        </Button>
      </form>
    </Container>
  );
};

export default AddWorkout;
