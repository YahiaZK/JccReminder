# JCC Reminder - Equipment Maintenance Logger

A Flutter application for managing heavy equipment maintenance schedules. The app tracks equipment working hours and sends push notifications when maintenance is due, helping ensure timely servicing of machinery and vehicles.

## Features

### Equipment Management

- **Add Equipment**: Register equipment with name, driver, model, and an optional image
- **Track Working Hours**: Monitor total working hours for each piece of equipment
- **Equipment Dashboard**: View all registered equipment at a glance
- **Edit & Delete**: Update equipment details or remove equipment

### Maintenance Tracking

- **Maintenance Records**: Create maintenance schedules per equipment (e.g., oil change, filter replacement)
- **Hours-Based Scheduling**: Set maintenance intervals based on working hours (e.g., every 250 hours)
- **Automatic Due Date Calculation**: The app calculates the next maintenance date based on average daily equipment usage
- **Maintenance History**: Track last maintenance date and hours for each service type

### Notifications

- **Push Notifications**: Receive daily reminders when maintenance is due
- **Scheduled Checks**: Cloud Functions run daily at 7:00 AM to check for upcoming maintenance
- **Toggle Notifications**: Enable or disable notifications from settings
- **Test Notifications**: Send test notifications to verify setup

### Authentication

- **Email/Password Sign-In**: Traditional authentication method
- **Google Sign-In**: Quick authentication with Google account
- **User-Specific Data**: Each user has their own equipment and maintenance records

