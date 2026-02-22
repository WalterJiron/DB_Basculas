USE Bascula;

GO

CREATE TRIGGER trg_Compra_Auditoria
ON Compra
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	
	INSERT INTO HistorialCompra (
		CodCompra,
		CodProvAnterior,
		CodProvNuevo,
		TotalCompraAnterior,
		TotalCompraNuevo,
		UsuarioModifico,
		Observacion
	)
	
	SELECT
		i.CodCompra,
		d.CodProv,
		i.CodProv,
		d.TotalCompra,
		i.TotalCompra,
		i.IdUser,
		'Actualización de la compra'
	FROM inserted as i
	INNER JOIN deleted as d ON i.CodCompra = d.CodCompra
	WHERE
		d.CodProv <> i.CodProv OR
		d.TotalCompra <> i.TotalCompra;
END;