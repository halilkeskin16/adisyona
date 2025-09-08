# Adisyona - Restaurant Management System

Adisyona is a comprehensive restaurant and cafe management application designed to streamline operations, track orders, and provide insightful business analytics. Built with Flutter, this application offers a cross-platform solution for managing tables, orders, kitchen workflow, and personnel, helping businesses enhance efficiency and profitability.

## ✨ Features

* **Table & Order Management:** Easily take orders directly from tables with a user-friendly interface and track the status of each table in real-time.
* **Automated Kitchen Workflow:** Orders are sent directly to the kitchen display system automatically, reducing manual errors and communication delays.
* **Advanced Sales Analytics:** Track best-selling products, analyze revenue per table, and monitor sales performance with detailed reports using dynamic charts.
* **Financial Tracking:** Calculate and display profit and loss statements to get a clear overview of your business's financial health.
* **Multi-Company Support:** The system supports multiple companies or branches, each with its own separate data and login credentials via Firebase Authentication.
* **Personnel & Role Management:** Register employees and assign specific roles and permissions to control access to different features.
* **PDF & Printing:** Generate and print reports or receipts directly from the application.

## 🚀 Technology Stack

Based on the `pubspec.yaml`, the core technologies used in this project are:

* **Framework:** Flutter
* **Programming Language:** Dart
* **Database:** Cloud Firestore (Firebase)
* **Authentication:** Firebase Authentication
* **State Management:** Provider
* **Charting:** fl_chart
* **PDF & Printing:** pdf, printing

## ⚙️ Installation

To get a local copy up and running, follow these simple steps.

1.  **Clone the repo**
    ```sh
    git clone [https://github.com/halilkeskin16/adisyona.git](https://github.com/halilkeskin16/adisyona.git)
    ```
2.  **Navigate to the project directory**
    ```sh
    cd adisyona
    ```
3.  **Install dependencies**
    ```sh
    flutter pub get
    ```
4.  **Run the app**
    ```sh
    flutter run
    ```

## Usage

After running the application, you can log in using your company's credentials. The system provides different dashboards and functionalities based on the user's role (Manager, Waiter, etc.).

1.  A waiter can select a table to place a new order.
2.  The order is instantly visible on the kitchen screen.
3.  A manager can access the analytics panel to view sales reports and profit/loss data.
