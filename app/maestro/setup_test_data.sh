#!/bin/bash
# Setup test data for NameDrill Learn Mode tests
# Run this before running learn_mode_flow.yaml

PACKAGE="com.namedrill.namedrill"
DB_PATH="/data/data/$PACKAGE/databases/namedrill.db"
PHOTOS_DIR="/data/data/$PACKAGE/app_flutter/photos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up test data for NameDrill Learn Mode..."

# Step 1: Push test image to device
echo "1. Pushing test image to device..."
adb push "$SCRIPT_DIR/test_assets/test_person.png" /sdcard/Download/test_person.png > /dev/null

# Step 2: Ensure photos directory exists
echo "2. Creating photos directory..."
adb shell run-as $PACKAGE mkdir -p $PHOTOS_DIR

# Step 3: Copy images using a workaround (run-as can't access /sdcard directly)
echo "3. Copying test images..."
# Use cat through stdin
adb shell "cat /sdcard/Download/test_person.png" | adb shell "run-as $PACKAGE sh -c 'cat > $PHOTOS_DIR/test_person_1.png'"
adb shell "cat /sdcard/Download/test_person.png" | adb shell "run-as $PACKAGE sh -c 'cat > $PHOTOS_DIR/test_person_2.png'"
adb shell "cat /sdcard/Download/test_person.png" | adb shell "run-as $PACKAGE sh -c 'cat > $PHOTOS_DIR/test_person_3.png'"

# Step 4: Insert database records
echo "4. Inserting test data into database..."
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

adb shell "run-as $PACKAGE sqlite3 $DB_PATH \"
DELETE FROM groups WHERE name LIKE 'Test%';
DELETE FROM people WHERE name IN ('Alice Smith', 'Bob Johnson', 'Carol White');
DELETE FROM learning_records WHERE id IN ('lr-1', 'lr-2', 'lr-3');

INSERT INTO groups (id, name, color, createdAt, updatedAt, sortOrder)
VALUES ('test-group-1', 'Test Learn Group', '#6366F1', '$NOW', '$NOW', 0);

INSERT INTO people (id, groupId, name, photoPath, notes, createdAt, updatedAt)
VALUES 
  ('test-person-1', 'test-group-1', 'Alice Smith', '$PHOTOS_DIR/test_person_1.png', 'Test person 1', '$NOW', '$NOW'),
  ('test-person-2', 'test-group-1', 'Bob Johnson', '$PHOTOS_DIR/test_person_2.png', 'Test person 2', '$NOW', '$NOW'),
  ('test-person-3', 'test-group-1', 'Carol White', '$PHOTOS_DIR/test_person_3.png', 'Test person 3', '$NOW', '$NOW');

INSERT INTO learning_records (id, personId, interval, easeFactor, nextReviewDate, reviewCount, lastReviewedAt)
VALUES 
  ('lr-1', 'test-person-1', 0, 2.5, '$NOW', 0, NULL),
  ('lr-2', 'test-person-2', 0, 2.5, '$NOW', 0, NULL),
  ('lr-3', 'test-person-3', 0, 2.5, '$NOW', 0, NULL);
\""

# Step 5: Verify
echo "5. Verifying data..."
COUNT=$(adb shell "run-as $PACKAGE sqlite3 $DB_PATH 'SELECT COUNT(*) FROM people WHERE groupId=\"test-group-1\";'")
echo "   People count: $COUNT"

LR_COUNT=$(adb shell "run-as $PACKAGE sqlite3 $DB_PATH 'SELECT COUNT(*) FROM learning_records WHERE id LIKE \"lr-%\";'")
echo "   Learning records: $LR_COUNT"

echo ""
echo "✅ Test data setup complete!"
echo "   - Group: Test Learn Group"
echo "   - People: Alice Smith, Bob Johnson, Carol White"
echo "   - All cards due for review"
echo ""
echo "You can now run: maestro test maestro/learn_mode_flow.yaml"
