# Learning Paths Feature - DeltaMind

## Overview

The Learning Paths feature in DeltaMind provides users with a structured, visually appealing way to organize their learning journey through any subject using a node-based graph visualization. This feature enables users to:

1. Generate AI-powered learning paths for any topic
2. Visualize their progress through an interactive graph
3. Track module completion status (locked, in-progress, done)
4. Link modules to existing content (notes, quizzes, flashcards)

## Technical Implementation

### Database Structure

The feature uses two main database tables:

**learning_paths**
- `id` - Unique UUID for the path
- `user_id` - User who owns the path
- `title` - Path title
- `description` - Path description
- `is_active` - Boolean flag for the active path
- `progress` - Integer (0-100) tracking completion percentage
- `created_at` - Timestamp
- `updated_at` - Timestamp

**learning_path_modules**
- `id` - Unique UUID for the module
- `path_id` - Foreign key to learning_paths
- `title` - Module title
- `description` - Module description
- `prerequisites` - Text describing prerequisites
- `dependencies` - Array of module IDs that must be completed first
- `resources` - Array of learning resources
- `learning_objectives` - Array of objectives
- `estimated_duration` - Text estimation of time needed
- `assessment` - Description of assessment method
- `additional_notes` - Optional additional information
- `module_id` - User-friendly module identifier
- `status` - Enum: "locked", "in-progress", "done"
- `position` - Integer for ordering modules
- `created_at` - Timestamp
- `updated_at` - Timestamp
- `note_id` - Optional link to a note
- `quiz_id` - Optional link to a quiz
- `deck_id` - Optional link to a flashcard deck

### Key Components

1. **Models**
   - `LearningPath`: Model representing a learning path
   - `LearningPathModule`: Model representing a module within a path

2. **Service Layer**
   - `LearningPathService`: Handles CRUD operations and AI generation
   - Integration with Gemini AI for path generation

3. **UI Components**
   - `LearningPathsPage`: List view of all learning paths
   - `GeneratePathDialog`: Dialog for creating new AI-generated paths
   - `LearningPathDetailPage`: Node-based visualization using the GraphView package

4. **Graph Visualization**
   - Uses the `graphview` package for node-graph layout
   - Supports BuchheimWalker algorithm for tree layout
   - Custom node styling based on module status

## Feature Highlights

### AI-Powered Path Generation

The system uses Google's Gemini AI to generate comprehensive learning paths. The prompt is engineered to create:

- Logical progression from beginner to advanced concepts
- Clear dependencies between modules
- Balanced visual structure for graph representation
- Consistent formatting and naming conventions

### Node Graph Visualization

The path is visualized as an interactive graph where:

- Nodes represent modules
- Edges represent dependencies between modules
- Node colors indicate status (locked, in-progress, done)
- Users can interact with nodes to view details and update status

### Active Path Tracking

Users can set one learning path as active, which:

- Appears on the dashboard
- Shows current progress
- Highlights the next module to complete

## Usage Flow

1. **Creating a Path**
   - Navigate to Learning Paths page
   - Click "Generate New Path"
   - Enter a learning topic
   - AI generates a structured path
   - Review and save the path

2. **Working with Paths**
   - Set a path as active
   - View the path in the graph visualization
   - Update module status as you progress
   - Link modules to notes, quizzes, or flashcard decks

3. **Tracking Progress**
   - Dashboard shows active path and progress
   - Learning Paths page shows all paths with progress indicators

## Future Enhancements

Potential improvements for future versions:

1. **Custom Path Creation**: Allow manual creation and editing of paths
2. **Advanced Graph Layouts**: Support for more layout algorithms
3. **Collaborative Paths**: Share paths with other users
4. **Path Templates**: Pre-built templates for common learning topics
5. **Path Analytics**: Detailed statistics on learning progress
6. **Gamification**: Achievement rewards for completing paths

## Technical Dependencies

- **graphview**: ^1.2.0 - For node-based graph visualization
- **uuid**: ^4.2.2 - For generating unique identifiers
- **google_generative_ai**: For Gemini AI integration
- **supabase_flutter**: For database and authentication

## Credits

- The graph visualization is powered by the GraphView package (https://pub.dev/packages/graphview)
- AI content generation powered by Google's Gemini API 