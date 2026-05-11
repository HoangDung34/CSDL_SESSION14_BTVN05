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
    WHERE dept_id = in_dept_id
      AND patient_id IS NULL
    LIMIT 1;
END //

CREATE PROCEDURE ProcessEmergencyAdmission(IN in_patient_id INT, IN in_doctor_id INT, IN in_appointment_time DATETIME, IN in_dept_id INT)
BEGIN
    DECLARE sp_bed_id INT;
    DECLARE sp_next_appointment_id INT;

    START TRANSACTION;

    IF NOT EXISTS (SELECT dept_id FROM Departments WHERE dept_id = p_dept_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu choi: Khoa khong ton tai';
    END IF;

    IF EXISTS (SELECT patient_id FROM Beds WHERE patient_id = p_patient_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu choi: Benh nhan dang luu tru';
    END IF;

    CALL Find_bed(in_dept_id, sp_bed_id);

    IF in_bed_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu choi: Khoa hien da het giuong';
    END IF;

    SELECT IFNULL(MAX(appointment_id), 0) + 1 INTO sp_next_appointment_id
    FROM Appointments;

    INSERT INTO Appointments(appointment_id, patient_id, doctor_id, appointment_date, status)
    VALUES (sp_next_appointment_id, in_patient_id, in_doctor_id, in_appointment_time, 'Pending');

    UPDATE Beds
    SET patient_id = in_patient_id
    WHERE bed_id = sp_bed_id;
    
    COMMIT;
    
    SELECT
        'Nhap vien thanh cong' AS message,
        sp_bed_id AS assigned_bed,
        sp_next_appointment_id AS appointment_id;
END //

DELIMITER ;