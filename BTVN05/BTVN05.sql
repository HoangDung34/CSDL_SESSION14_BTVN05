-- Phần A: Bản vẽ thiết kế kiến trúc 
/*
Thiết kế Giao tiếp: Trình bày phương án trao đổi dữ liệu: Procedure Master sẽ dùng loại tham số nào (IN/OUT/INOUT) để "hứng" kết quả mã giường từ Procedure phụ trả về?
	tạo 2 procedure
    procedure master
		kiểm tra : bệnh nhân, khoa có tông tại không
        procedure phụ tìm giường
        tạo lịch khám
        gán giường cho bệnh nhân
        COMMit nếu thành công
        rollback thất bại 
	procedure phụ
		tìm giường
        trả kết quả về procedure master
	cách trao đổi dữ liệu gị thủ tục CALL
    tham số sử dụng: in, out
    Giải thích
		vì đề yêu cầu trả về kết quả nên chọn tham số out
*/
-- Phần B: Triển khai Code & Kiểm thử
USE RikkeiClinicDB;

DELIMITER //

CREATE PROCEDURE SP_Find_Bed(IN in_dept_id INT, OUT out_bed_id INT)
BEGIN
    SELECT bed_id INTO out_bed_id
    FROM Beds
    WHERE dept_id = in_dept_id AND patient_id IS NULL
    LIMIT 1;
END //

CREATE PROCEDURE ProcessEmergencyAdmission(IN in_patient_id INT, IN in_doctor_id INT, IN in_appointment_date DATETIME, IN in_dept_id INT)
BEGIN
    DECLARE sp_bed_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Giao dich that bai - Da rollback' AS message;
    END;
    START TRANSACTION;

    IF NOT EXISTS (SELECT dept_id FROM Departments WHERE dept_id = in_dept_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu choi: Khoa khong ton tai';
    END IF;
    
    IF EXISTS (SELECT patient_id FROM Beds WHERE patient_id = in_patient_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu choi: Benh nhan dang luu tru';
    END IF;
    
    CALL SP_Find_Bed(in_dept_id, sp_bed_id);

    IF sp_bed_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu choi: Khoa hien da het giuong';
    END IF;

    INSERT INTO Appointments(appointment_id, patient_id, doctor_id, appointment_date, status)
    VALUES(107, in_patient_id, in_doctor_id, in_appointment_date, 'Pending');
    
    UPDATE Beds
    SET patient_id = in_patient_id
    WHERE bed_id = sp_bed_id;

    COMMIT;
    SELECT
        'Nhap vien thanh cong' AS message,
        sp_bed_id AS assigned_bed;
END //
DELIMITER ;
-- kiểm thử thành công
CALL ProcessEmergencyAdmission(3, 101, '2026-06-15 08:00:00', 2);
SELECT * FROM Beds;
SELECT * FROM Appointments;
-- kiểm thử hết giường
CALL ProcessEmergencyAdmission(3, 101, '2026-06-15 09:00:00', 3);
-- kiểm thử nội trú
CALL ProcessEmergencyAdmission(1, 101, '2026-06-15 10:00:00', 2);
-- kiểm thử khoa không tồn tại
CALL ProcessEmergencyAdmission(3, 101, '2026-06-15 11:00:00', 99);
