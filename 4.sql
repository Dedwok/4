-- Создание базы данных
CREATE DATABASE TourismManagement;
GO

USE TourismManagement;
GO

-- Таблица стран
CREATE TABLE Countries (
    CountryID INT PRIMARY KEY IDENTITY(1,1),
    CountryName NVARCHAR(100) NOT NULL,
    VisaRequired BIT DEFAULT 0,
    Description NVARCHAR(MAX),
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

-- Таблица клиентов
CREATE TABLE Clients (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Phone NVARCHAR(20) NOT NULL,
    PassportNumber NVARCHAR(20) NOT NULL,
    RegistrationDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
GO

-- Таблица туров
CREATE TABLE Tours (
    TourID INT PRIMARY KEY IDENTITY(1,1),
    CountryID INT FOREIGN KEY REFERENCES Countries(CountryID),
    Title NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    IsActive BIT DEFAULT 1,
    CONSTRAINT CHK_Dates CHECK (EndDate > StartDate)
);
GO

-- Таблица заказов
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    ClientID INT FOREIGN KEY REFERENCES Clients(ClientID),
    TourID INT FOREIGN KEY REFERENCES Tours(TourID),
    OrderDate DATETIME DEFAULT GETDATE(),
    PersonsCount INT DEFAULT 1,
    TotalPrice DECIMAL(10,2) NOT NULL,
    Status NVARCHAR(20) DEFAULT 'New',
    Notes NVARCHAR(MAX),
    CONSTRAINT CHK_PersonsCount CHECK (PersonsCount > 0)
);
GO

-- Вставка тестовых данных
INSERT INTO Countries (CountryName, VisaRequired, Description) VALUES
('Турция', 0, 'Популярное направление для пляжного отдыха'),
('Италия', 1, 'Страна с богатой культурой и историей'),
('Египет', 1, 'Отличные отели и древние пирамиды');
GO

INSERT INTO Clients (FirstName, LastName, Email, Phone, PassportNumber) VALUES
('Иван', 'Иванов', 'ivanov@example.com', '+79101234567', '1234567890'),
('Петр', 'Петров', 'petrov@example.com', '+79107654321', '0987654321');
GO

INSERT INTO Tours (CountryID, Title, Description, StartDate, EndDate, Price) VALUES
(1, 'Анталия - все включено', 'Отдых в 5* отеле', '2023-08-15', '2023-08-29', 85000),
(2, 'Рим - Флоренция - Венеция', 'Экскурсионный тур', '2023-09-01', '2023-09-10', 120000);
GO
