import React, { useEffect, useState } from "react";
import {
  Typography,
  List,
  Container,
  Paper,
  Alert,
  Box,
  Divider,
  Chip,
  Grid,
} from "@mui/material";
import { getMeals } from "../api";

const MealLog = () => {
  const [meals, setMeals] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchMeals = async () => {
      try {
        const mealsData = await getMeals();
        setMeals(mealsData);
      } catch (error) {
        setError("Failed to load meals. Please try again later.");
      } finally {
        setLoading(false);
      }
    };

    fetchMeals();
  }, []);

  if (loading) {
    return (
      <Container maxWidth="md">
        <Typography>Loading meals...</Typography>
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
        Meal Log
      </Typography>

      {meals.length === 0 ? (
        <Alert severity="info">No meals recorded yet.</Alert>
      ) : (
        <List>
          {meals.map((meal, index) => (
            <Paper key={index} elevation={2} sx={{ mb: 2, p: 2 }}>
              <Grid container spacing={2}>
                <Grid xs={12}>
                  <Typography variant="h6">{meal.meal_name}</Typography>
                  <Typography color="text.secondary" gutterBottom>
                    Date: {meal.date_eaten}
                  </Typography>
                </Grid>

                <Grid xs={12} sm={6}>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>
                      Nutritional Information
                    </Typography>
                    <Typography>Calories: {meal.calories}</Typography>
                    <Typography>Protein: {meal.protein}g</Typography>
                    <Typography>Carbs: {meal.carbs}g</Typography>
                    <Typography>Fat: {meal.fat}g</Typography>
                  </Box>
                </Grid>

                <Grid xs={12} sm={6}>
                  <Typography variant="subtitle2" gutterBottom>
                    Ingredients
                  </Typography>
                  <Box sx={{ display: "flex", flexWrap: "wrap", gap: 1 }}>
                    {meal.ingredients.map((ingredient, idx) => (
                      <Chip
                        key={idx}
                        label={ingredient.name}
                        size="small"
                        variant="outlined"
                      />
                    ))}
                  </Box>
                </Grid>
              </Grid>
              {index < meals.length - 1 && <Divider sx={{ mt: 2 }} />}
            </Paper>
          ))}
        </List>
      )}
    </Container>
  );
};

export default MealLog;
