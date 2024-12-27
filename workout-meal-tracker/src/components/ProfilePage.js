import React from "react";
import { Container, Typography, Button, Paper, Grid } from "@mui/material";
import { useNavigate } from "react-router-dom";

const ProfilePage = ({ handleLogout }) => {
  const navigate = useNavigate();
  const username = localStorage.getItem("username");

  return (
    <Container maxWidth="sm" className="mt-8">
      <Paper className="p-6">
        <div className="flex justify-between items-center mb-6">
          <Typography variant="h4">Profile</Typography>
          <Button
            variant="outlined"
            color="primary"
            onClick={() => navigate("/")}
          >
            Back
          </Button>
        </div>

        {/* User Information */}
        <Grid container spacing={2} className="mb-6">
          <Grid item xs={12}>
            <Typography variant="subtitle1" color="textSecondary">
              Username
            </Typography>
            <Typography variant="h6">{username}</Typography>
          </Grid>
          {/* Add more user information fields here */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" color="textSecondary">
              Weight Goal
            </Typography>
            <Typography variant="h6">Gain Weight</Typography>
          </Grid>
          <Grid item xs={12}>
            <Typography variant="subtitle1" color="textSecondary">
              Daily Calorie Goal
            </Typography>
            <Typography variant="h6">2500 kcal</Typography>
          </Grid>
        </Grid>

        {/* Action Buttons */}
        <div className="space-y-3">
          <Button variant="contained" color="primary" fullWidth>
            Edit Profile
          </Button>
          <Button
            variant="outlined"
            color="error"
            fullWidth
            onClick={handleLogout}
          >
            Logout
          </Button>
        </div>
      </Paper>
    </Container>
  );
};

export default ProfilePage;
