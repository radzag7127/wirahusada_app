# Wismon Keuangan Backend API

Backend API for Wismon Keuangan - Financial Management System built with Node.js, TypeScript, and Express.js.

## 🚀 Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn package manager

### Installation

1. Navigate to the backend directory:

```bash
cd be_wismon_keuangan
```

2. Install dependencies:

```bash
npm install
```

### Development

Start the development server with hot reload:

```bash
npm run dev
```

The server will start on `http://localhost:3000`

### Available Scripts

- `npm run dev` - Start development server with nodemon
- `npm run dev:watch` - Start development server with ts-node
- `npm run build` - Build the project for production
- `npm run start` - Start the production server
- `npm run clean` - Remove build artifacts

### API Endpoints

- `GET /` - Welcome message and API status
- `GET /health` - Health check endpoint

## 🛠️ Tech Stack

- **Runtime**: Node.js
- **Language**: TypeScript
- **Framework**: Express.js
- **Development**: nodemon, ts-node

## 📁 Project Structure

```
be_wismon_keuangan/
├── src/
│   └── index.ts          # Application entry point
├── dist/                 # Compiled JavaScript (after build)
├── package.json
├── tsconfig.json
└── README.md
```

## 🔧 Configuration

The application uses the following configuration:

- Port: 3000 (default) or `PORT` environment variable
- TypeScript target: ES2022
- Module system: CommonJS

## 📝 Development Notes

- Source files are located in the `src/` directory
- Compiled files are output to the `dist/` directory
- The development server automatically restarts when files change
- Strict TypeScript configuration is enabled for better code quality
