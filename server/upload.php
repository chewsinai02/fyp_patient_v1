<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

try {
    if (!isset($_FILES['image'])) {
        throw new Exception('No image file received');
    }

    $file = $_FILES['image'];
    $fileName = time() . '_' . basename($file['name']);
    $uploadDir = 'uploads/chat_images/';
    $uploadPath = $uploadDir . $fileName;

    // Create directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    // Move uploaded file
    if (move_uploaded_file($file['tmp_name'], $uploadPath)) {
        // Generate URL
        $baseUrl = 'http://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']);
        $imageUrl = $baseUrl . '/' . $uploadPath;

        // Store in database
        $pdo = new PDO(
            "mysql:host=mydb.cdsagqe648ba.ap-southeast-2.rds.amazonaws.com;dbname=mydb1",
            "admin",
            "admin1234"
        );

        $stmt = $pdo->prepare("INSERT INTO chat_images (filename, url) VALUES (?, ?)");
        $stmt->execute([$fileName, $imageUrl]);

        echo json_encode([
            'success' => true,
            'url' => $imageUrl
        ]);
    } else {
        throw new Exception('Failed to move uploaded file');
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?> 