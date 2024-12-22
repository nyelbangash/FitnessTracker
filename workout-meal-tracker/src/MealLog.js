// MealLog.js
import React, { useEffect, useState } from "react";
import {
  Typography,
  List,
  ListItem,
  ListItemText,
  Container,
} from "@mui/material";
import { getMeals } from "./api";

const MealLog = () => {
  const [meals, setMeals] = useState([]);

  useEffect(() => {
    const fetchMeals = async () => {
      try {
        const mealsData = await getMeals();
        setMeals(mealsData);
      } catch (error) {
        // Handle error, e.g., display error message
      }
    };

    fetchMeals();
  }, []);

  return (
    <Container maxWidth="sm">
      <Typography variant="h4" align="center" gutterBottom>
        Meal Log
      </Typography>
      <List>
        {meals.map((meal) => (
          <ListItem key={meal.id}>
            <ListItemText
              primary={meal.mealName}
              secondary={
                <>
                  <Typography
                    component="span"
                    variant="body2"
                    color="textPrimary"
                  >
                    Date: {meal.date}
                  </Typography>
                  <br />
                  <Typography
                    component="span"
                    variant="body2"
                    color="textPrimary"
                  >
                    Calories: {meal.calories}
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

export default MealLog;
