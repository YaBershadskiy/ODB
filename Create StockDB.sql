CREATE DATABASE StockIndicatorDB;

GO

USE StockIndicatorDB

CREATE TABLE Stocks(
	Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	StockName VARCHAR(20) NOT NULL
);

CREATE TABLE Price(
	Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	PriceDate DATE,
	OpenPrice DECIMAL(9,4),
	HighPrice DECIMAL(9,4),
	LowPrice DECIMAL(9,4),
	ClosePrice DECIMAL(9,4),
	PriceChangeValue DECIMAL(9,4),
	GrowthProbability DECIMAL(9,4),
	IsGrow BIT, -- 1 is UP, 0 is DOWN
	StockId INT FOREIGN KEY REFERENCES Stocks(Id)
);

CREATE TABLE ExternalIndicator(
	Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Name VARCHAR(100),
	GrowthProbability DECIMAL(9,4),
	PriceId INT NOT NULL FOREIGN KEY REFERENCES Price(Id)
);

CREATE TABLE StockForecast(
	Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	PriceDate DATE,
	NewPrice DECIMAL(9,4),
	StockId INT NOT NULL FOREIGN KEY REFERENCES Stocks(Id)
);

GO

CREATE FUNCTION GetTotalProb (@priceId INT)
RETURNS DECIMAL(9,4)
AS 
BEGIN 
	DECLARE @res DECIMAL(9,4) = 0
	SELECT @res = AVG(GrowthProbability)FROM ExternalIndicator WHERE PriceId = @priceId AND GrowthProbability != 0
RETURN @res
END

GO

CREATE PROCEDURE dbo.GetGrowthProbabiliries @priceId INT
AS
SELECT * FROM ExternalIndicator WHERE PriceId = @priceId

GO

CREATE PROCEDURE dbo.SetGrowthProb @priceId INT
AS
UPDATE Price SET Price.GrowthProbability = dbo.GetTotalProb(@priceId) WHERE Price.Id = @priceId

GO

CREATE TRIGGER SetIsGrow ON Price AFTER INSERT AS 
BEGIN
	DECLARE @openPrice DECIMAL(9,4)
	SELECT @openPrice = OpenPrice FROM inserted

	DECLARE @closePrice DECIMAL(9,4)
	SELECT @closePrice = ClosePrice FROM inserted
	
	IF(@closePrice>@openPrice)	
		UPDATE Price SET IsGrow = 1 WHERE Price.Id = (SELECT id FROM inserted) 
	ELSE 
		UPDATE Price SET IsGrow = 0 WHERE Price.Id = (SELECT id FROM inserted) 
END

GO

CREATE TRIGGER SetPriceChangeValue ON Price AFTER INSERT AS 
BEGIN
	DECLARE @openPrice DECIMAL(9,4)
	SELECT @openPrice = OpenPrice FROM inserted

	DECLARE @closePrice DECIMAL(9,4)
	SELECT @closePrice = ClosePrice FROM inserted
	
	UPDATE Price SET PriceChangeValue = @closePrice - @openPrice WHERE Price.Id = (SELECT id FROM inserted) 
	
END

GO


