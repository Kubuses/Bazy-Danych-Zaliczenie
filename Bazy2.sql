--Skrypt 1

-- Tworzenie bazy danych
CREATE DATABASE Przychodnia;

-- Prze³¹czanie kontekstu na bazê danych
USE Przychodnia;

-- Tworzenie tabeli Pracownicy
CREATE TABLE Pracownicy (
    Id INT PRIMARY KEY,
    Imie NVARCHAR(255),
    Nazwisko NVARCHAR(255),
    numer_identyfikacyjny INT
);

-- Tworzenie tabeli Wizyty
CREATE TABLE Wizyty (
    Id INT PRIMARY KEY,
    DataDzien DATE,
    Godzina TIME,
    PracownikId INT,
    LekarzId INT,
    LiczbaDiagnoz INT,
    FOREIGN KEY (PracownikId) REFERENCES Pracownicy(Id)
);

-- Tworzenie tabeli Lekarze
CREATE TABLE Lekarze (
    Id INT PRIMARY KEY,
    Imie NVARCHAR(255),
    Nazwisko NVARCHAR(255),
    Specjalnosc NVARCHAR(255),
    Wiek INT
);

-- Tworzenie tabeli Diagnozy
CREATE TABLE Diagnozy (
    Id INT PRIMARY KEY,
    Nazwa NVARCHAR(255),
    WizytaId INT,
    FOREIGN KEY (WizytaId) REFERENCES Wizyty(Id)
);

-- Tworzenie relacji miêdzy tabelami
ALTER TABLE Wizyty
ADD FOREIGN KEY (LekarzId) REFERENCES Lekarze(Id);


--Skrypt 2

INSERT INTO Pracownicy (Id, Imie, Nazwisko, numer_identyfikacyjny)
VALUES (3, 'Janusz', 'Kowal', 1002),
       (4, 'Aneta', 'Nowakowska', 1003);

INSERT INTO Lekarze (Id, Imie, Nazwisko, Specjalnosc, Wiek)
VALUES (3, 'Henryk', 'Sienkiewicz', 'Ortopeda', 55),
       (4, 'Ma³gorzata', 'Sk³odowska-Curie', 'Ginekolog', 45);


INSERT INTO Wizyty (Id, DataDzien, Godzina, PracownikId, LekarzId, LiczbaDiagnoz)
VALUES (6, '2022-01-06', '09:00:00', 3, 3, 2),
       (7, '2022-01-07', '10:30:00', 4, 4, 3),
       (8, '2022-01-08', '14:00:00', 3, 3, 1),
       (9, '2022-01-09', '15:30:00', 4, 4, 2),
       (10, '2022-01-10', '16:00:00', 3, 3, 3);

INSERT INTO Diagnozy (Id, Nazwa, WizytaId)
VALUES (8, 'Zapalenie jelit', 6),
       (9, 'Zapalenie nerek', 7),
       (10, 'Zapalenie skóry', 8),
       (11, 'Zapalenie trzustki', 9),
       (12, 'Zapalenie w¹troby', 10);


--Skrypt 3

--Regu³a - wiek lekarzy nie mo¿e byæ wiêkszy ni¿ 75 lat

CREATE CHECK CONSTRAINT CHK_AgeLimit
ON Lekarze
    (Wiek <= 75)

--Funkcja skalarna bior¹ca ID lekarza i wyœwietlaj¹ca dane o nim

CREATE FUNCTION dbo.GetLekarz (@lekarzId INT)
RETURNS TABLE
AS
RETURN 
    SELECT Nazwisko, Imie, Wiek
    FROM Lekarze
    WHERE Id = @lekarzId

--Funkcja tabularna bior¹ca numer wizyty i wyœwietlaj¹ca listê diagnoz

CREATE FUNCTION dbo.GetDiagnozy (@wizytaId INT)
RETURNS TABLE
AS
RETURN 
    SELECT Nazwa
    FROM Diagnozy
    WHERE WizytaId = @wizytaId
