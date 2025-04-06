# Load libraries
library(tidyverse)
library(lubridate)

# List all CSVs
files <- list.files(pattern = "*.csv")

# Load and combine all datasets
q1_2019 <- read_csv("Divvy_Trips_2019_Q1.csv")

q1_2020 <- read_csv("Divvy_Trips_2020_Q1.csv")

# View structure
glimpse(q1_2019)
glimpse(q1_2020)



#cleaning and standardizing code
q1_2019_clean <- q1_2019 %>%
  rename(
    ride_id = trip_id,
    started_at = start_time,
    ended_at = end_time,
    start_station_name = from_station_name,
    start_station_id = from_station_id,
    end_station_name = to_station_name,
    end_station_id = to_station_id,
    member_casual = usertype
  ) %>%
  mutate(
    ride_id = as.character(ride_id),  # 🔥 THE FIX
    rideable_type = "docked_bike",
    member_casual = if_else(member_casual == "Subscriber", "member", "casual"),
    start_lat = NA,
    start_lng = NA,
    end_lat = NA,
    end_lng = NA
  ) %>%
  select(
    ride_id, rideable_type, started_at, ended_at,
    start_station_name, start_station_id,
    end_station_name, end_station_id,
    start_lat, start_lng, end_lat, end_lng, member_casual
  )



# Combine the cleaned 2019 and the 2020 data
all_trips <- bind_rows(q1_2019_clean, q1_2020)
colnames(all_trips)

#calculate trip times
all_trips$ride_length <- difftime(all_trips$ended_at, all_trips$started_at, units = "mins")
#Specific day of week column
all_trips$day_of_week <- weekdays(as.Date(all_trips$started_at))

#check created columns
head(all_trips[, c("ride_length", "day_of_week")])

#remove missing value trips
all_trips <- na.omit(all_trips)
all_trips <- all_trips %>%
  filter(ride_length > 0)

#check made changes
glimpse(all_trips)
summary(all_trips$ride_length)

#before calculations make sure data is correct type
all_trips$ride_length <- as.numeric(all_trips$ride_length)
all_trips$ride_length <- as.numeric(as.character(all_trips$ride_length))

#Check the type using summary 
summary(all_trips$ride_length)

#Remove Outliers
all_trips <- all_trips %>%
  filter(ride_length >= 1, ride_length < 360)

#Check summary again
summary(all_trips$ride_length)

#Member vs Casual calculations
all_trips %>%
  group_by(member_casual) %>%
  summarise(
    avg_ride = mean(ride_length),
    median_ride = median(ride_length),
    max_ride = max(ride_length),
    min_ride = min(ride_length)
  )

all_trips %>%
  group_by(member_casual, day_of_week) %>%
  summarise(avg_duration = mean(ride_length)) %>%
  arrange(member_casual, day_of_week)

#Fix Weekday Order
all_trips$day_of_week <- ordered(all_trips$day_of_week,
                                 levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
)

#Visualizations
library(ggplot2)

#Bar Chart: Avg Ride Duration by Day + User Type
all_trips %>%
  group_by(member_casual, day_of_week) %>%
  summarise(avg_duration = mean(ride_length)) %>%
  ggplot(aes(x = day_of_week, y = avg_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(title = "Average Ride Duration by Day",
       x = "Day of Week", y = "Average Duration (mins)", fill = "User Type") +
  theme_minimal()

#Chart 2: Number of Rides by Weekday & User Type
all_trips %>%
  group_by(member_casual, day_of_week) %>%
  summarise(number_of_rides = n()) %>%
  ggplot(aes(x = day_of_week, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(title = "Total Number of Rides by Day",
       x = "Day of Week",
       y = "Number of Rides",
       fill = "User Type") +
  theme_minimal()
