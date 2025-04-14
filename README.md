# ArtistryHub  

<!-- Cover -->
**Project Title:** ArtistryHub <br>
**Student:** Batyrkhan Tursumbekov <br>
**Group:** SE-2321 <br>
**Instructor:** Nurgaliyeva Symbat <br>
**Date:** April 14, 2025 <br>



## Project Description

### General Idea:

**ArtistryHub** is a mobile app where users can share music they are listening to and post audio clips. It works like a social network focused on music.


### Purpose:

 The idea was inspired by apps like **Airbuds FM**. I wanted to make something that connects people through music. It solves the problem of feeling disconnected by allowing people to discover songs and connect through shared taste.



### Main Features:

 - **Post music** and audio clips with text
 - **See posts** from others
 - **Comment** on posts


### Target Audience:

This app is made for students, music lovers, and anyone who enjoys sharing and discovering music.

### Use Case Scenario:

A student listens to a song while studying. They post a clip with a message like *“perfect focus vibes.”* Other user sees the post, likes it, and discovers a new favorite track.


## Tools and Technologies Used

### Tools:
 - **Flutter:** The framework used to build the app.
 - **Dart:** The programming language for Flutter.
 - **SQFLite:** A local database to store music data (like titles or comments) on the user’s device.
 - **Provider:** Manages app state, like keeping track of user data or track lists. 
 - **HTTP:** Used to fetch or send data to online services (e.g., APIs for artwork or user info).
 - **File Picker:** Lets users select files from their device to upload music.
 - **Google Fonts:** Adds custom fonts to make the app’s text look better. 
 - **Just Audio:** Plays audio files.
 - **Shared Preferences:** Saves small pieces of data, like user settings on the device.
 - **Permission Handler:** Manages access to device features like storage or camera for uploading music.
 - **Path Provider and Path:** Helps manage file storage paths for saving music or other data locally.
 - **Intl:** Formats dates and numbers, useful for displaying timestamps on posts.
 - **LastFM API:** Provides music data


## Application Architecture & Screens

### App Structure and Navigation:

 - `Feed Page`: Shows a scrollable list of posts.
 - `Post Page`: Lets users add new post with music and description.
 - `Profile Page`: Displays the user’s posts and basic info.
 - `Search Page`: Allows searching for music.
 - `Settings Page`: Allows user to change app theme
 - `Detailed Post Page`: Allows user to observe and add comments

## Methodology and Mockups:

 - **Planning:** Designed basic screens (`Feed`, `Post`, `Profile`, `Search`, `Settings`, `Detailed Post`) and decided on features like uploading and commenting.
 - **Mockups:** Looked for Figma designs related to music and scoial media to visualize the app.
 - **Development:** Built the app in Flutter, starting with the feed screen, then adding upload and comment features.
 - **Testing:** Checked if uploads worked, comments saved, and screens loaded correctly.



