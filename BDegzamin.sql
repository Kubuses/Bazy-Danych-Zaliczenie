--Skrypt1: Tworzenie tabel i powi�za� mi�dzy tabelami

CREATE DATABASE HomeMedicine;

USE HomeMedicine;

CREATE TABLE Medicines (
    MedicineID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(50) NOT NULL,
    Company NVARCHAR(50) NOT NULL,
    PurchaseDate DATE NOT NULL,
    NumberOfAilments INT NOT NULL,
    ResidentID INT NOT NULL,
    FOREIGN KEY (ResidentID) REFERENCES Residents(ResidentID)
);

CREATE TABLE Residents (
    ResidentID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    Age INT NOT NULL
);

CREATE TABLE Ailments (
    AilmentID INT PRIMARY KEY IDENTITY(1,1),
    PolishName NVARCHAR(50) NOT NULL,
    EnglishName NVARCHAR(50) NOT NULL
);

CREATE TABLE MedicineAilments (
    MedicineID INT NOT NULL,
    AilmentID INT NOT NULL,
    PRIMARY KEY (MedicineID, AilmentID),
    FOREIGN KEY (MedicineID) REFERENCES Medicines(MedicineID),
    FOREIGN KEY (AilmentID) REFERENCES Ailments(AilmentID)
);



--Skrypt 2: Wprowadzanie danych do tabel (po 2 dane do tabel s�ownikowych i 5 pozosta�e)

INSERT INTO Ailments (PolishName, EnglishName) 
VALUES ('B�l g�owy', 'Headache'), ('B�l gard�a', 'Sore throat');

INSERT INTO Residents (FirstName, LastName, Type, Age) 
VALUES ('Jan', 'Kowalski', 'Tata', 35), ('Anna', 'Nowak', 'Mama', 32);

INSERT INTO Medicines (Name, Company, PurchaseDate, NumberOfAilments, ResidentID)
VALUES ('Polopiryna', 'Polfarma', '2021-12-15', 2, 1), ('Ibuprofen', 'Galena', '2021-11-30', 1, 2);

INSERT INTO MedicineAilments (MedicineID, AilmentID)
VALUES (1, 1), (1, 2), (2, 1);


--Skrypt 3: Utw�rz:
--- regu�a: wiek domownika nie wi�kszy ni� 100 lat
--- funkcja skalarna: Wej�cie: nazwa leku, data zakupu, Wyj�cie: Data zakupu, jaka firma wykona�a ten lek, Nazwisko i Imi� domownika, typ domownika
--- funkcja tabularna: Wej�cie: numer Dolegliwo�ci, Wyj�cie: Nazwa leku, Nazwa Dolegliwo�ci

CREATE RULE check_age
AS 
    @age <= 100


CREATE FUNCTION get_medicine_details(@name NVARCHAR(50), @purchase_date DATE)
RETURNS TABLE 
AS
RETURN
    SELECT m.PurchaseDate, m.Company, r.LastName + ' ' + r.FirstName as "FullName", r.Type
    FROM Medicines m
    JOIN Residents r ON m.ResidentID = r.ResidentID
    WHERE m.Name = @name AND m.PurchaseDate = @purchase_date


CREATE FUNCTION get_ailment_medicines(@ailment_id INT)
RETURNS TABLE
AS
RETURN
    SELECT m.Name, a.PolishName
    FROM Medicines m
    JOIN MedicineAilments ma ON ma.MedicineID = m.MedicineID
    JOIN Ailments a ON ma.AilmentID = a.AilmentID
    WHERE ma.AilmentID = @ailment_id


--Widoki:
--1.
CREATE VIEW ResidentsWithMedicines AS
SELECT r.FirstName, r.Type, m.Name
FROM Residents r
JOIN Medicines m ON r.ResidentID = m.ResidentID
ORDER BY r.FirstName ASC

SELECT * FROM ResidentsWithMedicines

--2.
CREATE VIEW MedicinesWithAilments AS
SELECT m.Name, COUNT(ma.AilmentID) as "NumberOfAilments"
FROM Medicines m
JOIN MedicineAilments ma ON ma.MedicineID = m.MedicineID
GROUP BY m.Name

SELECT * FROM MedicinesWithAilments

--3.
CREATE VIEW AilmentsByResident AS
SELECT a.PolishName
FROM Ailments a
JOIN MedicineAilments ma ON ma.AilmentID = a.AilmentID
JOIN Medicines m ON ma.MedicineID = m.MedicineID
JOIN Residents r ON m.ResidentID = r.ResidentID

SELECT * FROM AilmentsByResident


--Skrypt 4: Napisa� skrypt, kt�ry (z wykorzystaniem kursora) poka�e wyniki np. w nast�puj�cej postaci:

DECLARE @name NVARCHAR(50), @company NVARCHAR(50), @firstname NVARCHAR(50), @type NVARCHAR(50), @age INT
DECLARE @counter INT = 0

DECLARE cursor_medicines CURSOR FOR
    SELECT m.Name, m.Company, r.FirstName, r.Type, r.Age
    FROM Medicines m
    JOIN Residents r ON m.ResidentID = r.ResidentID

OPEN cursor_medicines

PRINT 'Nazwa leku' + REPLICATE(' ', 17 - LEN('Nazwa leku')) +
       'Firma' + REPLICATE(' ', 14 - LEN('Firma')) +
       'Domownik' + REPLICATE(' ', 15 - LEN('Domownik')) +
       'Typ' + REPLICATE(' ', 14 - LEN('Typ')) +
       'Wiek'

PRINT REPLICATE('-', 67)

FETCH NEXT FROM cursor_medicines INTO @name, @company, @firstname, @type, @age

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @name + REPLICATE(' ', 17 - LEN(@name)) +
          @company + REPLICATE(' ', 14 - LEN(@company)) +
          @firstname + REPLICATE(' ', 15 - LEN(@firstname)) +
          @type + REPLICATE(' ', 14 - LEN(@type)) +
          CONVERT(NVARCHAR(50), @age)
    SET @counter += 1

    FETCH NEXT FROM cursor_medicines INTO @name, @company, @firstname, @type, @age
END

PRINT REPLICATE('-', 67)
PRINT 'Lek�w w bazie jest: ' + CONVERT(NVARCHAR(50), @counter)

CLOSE cursor_medicines
DEALLOCATE cursor_medicines

--Skrypt 5: Napisa� trigger, kt�ry po wstawieniu/usuni�ciu dolegliwo�ci do leku uaktualni liczb� dolegliwo�ci w tym leku
CREATE TRIGGER update_ailments_count
ON MedicineAilments
AFTER INSERT, DELETE
AS
BEGIN
    UPDATE m
    SET m.AilmentCount = (SELECT COUNT(ma.AilmentID) FROM MedicineAilments ma WHERE ma.MedicineID = m.MedicineID)
    FROM Medicines m
    JOIN inserted i ON i.MedicineID = m.MedicineID
END


--Skrypt 6: Utworzy� procedur� sk�adowan�, kt�ra dopisze nowego domownika do bazy oraz napisa� skrypt wywo�uj�cy
--t� procedur�
--UWAGA!!!. W przypadku powtarzania si� imienia, typu domownika i wieku domownika procedura wygeneruje b��d
--numeryczny: wpisz jaki lub tekstowy.

CREATE PROCEDURE AddResident
    @firstname NVARCHAR(50),
    @lastname NVARCHAR(50),
    @type NVARCHAR(50),
    @age INT
AS
BEGIN
    DECLARE @error INT

    --Checking if the resident already exists
    SELECT @error = COUNT(*)
    FROM Residents
    WHERE FirstName = @firstname AND LastName = @lastname AND Type = @type AND Age = @age

    IF @error > 0
    BEGIN
        RAISERROR('Resident already exists', 16, 1)
        RETURN
    END

    --Inserting the new resident
    INSERT INTO Residents (FirstName, LastName, Type, Age)
    VALUES (@firstname, @lastname, @type, @age)
END

EXEC AddResident 'Jan', 'Kowalski', 'Tato', 45