AI Prompting Outline: Fleet Driver Flutter App

Project Context: Fleet Management System

This project is a comprehensive logistics and fleet management system for a company that rents out trucks. It consists of two main components communicating via REST APIs:

Web App (Admin Backend): Handled by the lead developer. Admins use this dashboard to assign drivers to routes, manage truck details/manifests, monitor live driver locations, handle accounting (fuel consumption), and chat with drivers.

Mobile App (Driver Frontend): Handled by you (the OJT student) using Flutter. Drivers use this app to:

Securely log in with strict device hardware binding (1 account = 1 specific phone).

View currently assigned job orders and routes.

Upload required pre-ride photos (truck condition, odometer, manifest).

Launch external navigation apps (Waze/Google Maps).

Continuously stream their GPS location to the admin dashboard every 60 seconds (background polling).

Upload fuel receipts and chat with admins mid-ride.

Upload final post-ride photos to complete the job.

This document provides a step-by-step prompt outline to build the Driver Mobile App module by module using an AI coding assistant.
