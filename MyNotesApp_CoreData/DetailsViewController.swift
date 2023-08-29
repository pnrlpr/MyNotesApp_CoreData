//
//  DetailsViewController.swift
//  MyNotesApp_CoreData
//
//  Created by PINAR KALKAN on 22.08.2023.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var kaydetButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var sizeTextField: UITextField!
    
    var secilenUrunIsmi = ""
    var secilenUrunId: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //Eğer seçilen ürün ismi boş değilse
        //Yani + butonuna tıklayarak değil de
        //önceden kaydedilmiş ürün seçildiyse
        if secilenUrunIsmi != "" {
            
            kaydetButton.isHidden = true
            
            //Core Data seçilen ürün bilgilerini göster
            
            if let uuidString = secilenUrunId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MyNotes")
                //"id = %@" bu şu demek:
                // id, uuidString'e eşit olanları getir!
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            if let isim = sonuc.value(forKey: "name") as? String {
                                nameTextField.text = isim
                            }
                            
                            if let fiyat = sonuc.value(forKey: "price") as? Int {
                                priceTextField.text = String(fiyat)
                            }
                            
                            if let beden = sonuc.value(forKey: "size") as? String {
                                sizeTextField.text = beden
                            }
                            
                            if let gorselData = sonuc.value(forKey: "image") as? Data {
                                let image = UIImage(data: gorselData)
                                imageView.image = image
                            }
                        }
                    }
                    
                    
                } catch {
                    print("Hata var")
                }
                
                
            }
            
        } else {
            
            kaydetButton.isHidden = false
            kaydetButton.isEnabled = false
            //Demek ki + butonuna tıklayarak geldi
            nameTextField.text = ""
            priceTextField.text = ""
            sizeTextField.text = ""
        }
        
        
        //Ekranda herhangi bir yere basınca klavyenin kapanması
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        //GÖRSELE TIKLAYINCA FOTO EKLEME
        //İmageview'u kullanıcının etkileşime girebileceği bir hale getirir (alttaki satır)
        imageView.isUserInteractionEnabled = true
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(chooseImage))
        imageView.addGestureRecognizer(imageGestureRecognizer)
        
    }
    
    @objc func chooseImage (){
        //Görsele tıklandığında buraya ne yazarsan o olacak
        let picker = UIImagePickerController()
        picker.delegate = self
        //Bunları yazınca hata veriyor. Bunun için;
        //DetailsViewController'a UIImagePickerControllerDelegate, UINavigationControllerDelegate  eklenmeli
        
        //Pickerın özelliklerini seçtik
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    //Görseli seçtikten sonra ne olacak? Görseli imageview olarak kaydetmemiz lazım
    //Media seçme işlemi bitince ne yapılacağımı belirten fonk
    //didfinish yazınca çıkıyor
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        imageView.image = info[.editedImage] as? UIImage
        
        //Görsel seçilirse kaydet Butonu aktif olsun
        kaydetButton.isEnabled = true
        
        self.dismiss(animated: true, completion: nil) //image picker controller'ı kapatır
        
    //NOT: App ilk açıldığında "Fotolara erişmek için" diye mesaj yazsın istiyorsan;
        //Onu Info.plist dosyasında yaptık
    }
    
    
    @objc func closeKeyboard (){
        //Ekranın herhangi bir yerine tıklandığında buraya ne yazarsan o olacak
        view.endEditing(true)
    }
  
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        //Kaydetme için Core Date kullanıyoruz (lokale kaydeder)
        //Bunun için AppDelegate'a ulaşmamız lazım:
        //Yani AppDelegare.swift dosyasını bir değişkene eşitliyoruz:
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //MyNotesApp_CoreData.xcdatamodelld klasöründeki entityler ile ilerliyoruz
        //forEntityName: "MyNotes" xcdatamodelld'deki entity'nin adı
        let MyNotes = NSEntityDescription.insertNewObject(forEntityName: "MyNotes", into: context)
        MyNotes.setValue(nameTextField.text!, forKey: "name")
        MyNotes.setValue(sizeTextField.text!, forKey: "size")
        
        //price int olduğu için if let ile yap:
        if let price = Int(priceTextField.text!){
            MyNotes.setValue(price, forKey: "price")
        }
        
        MyNotes.setValue(UUID(), forKey: "id")
        
        //image binary data olarak seçmiştik.
        //görseli dataya çevir
        let data = imageView.image!.jpegData(compressionQuality: 0.5) //Sondaki sıkıştırma oranı
        MyNotes.setValue(data, forKey: "image")
        
        
        //Tüm verileri aldık. Kaydet:
        do {
            try context.save()
            print("Kayıt edildi")
        } catch {
            print("Hata Var")
        }
        
        //Bir önceki ekrana dönmeden önce kaydettiğimiz verileri bildirmemiz lazım
        //Yani biz bir veri kaydettik diye diğer ViewControllerlara haber ver
        //Bu işlemi yaptıktan sonra diğer VC'lerden yeni verileri çekebilirsin!!!
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "veriGirildi"), object: nil)
        
        //Verileri kaydedince bir önceki ekrana geri dönmesi için
        self.navigationController?.popViewController(animated: true)
    }
    
}
