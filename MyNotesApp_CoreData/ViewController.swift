//
//  ViewController.swift
//  MyNotesApp_CoreData
//
//  Created by PINAR KALKAN on 21.08.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenIsım = ""
    var secilenUUID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        
        //İlk sayfada üstteki + butonunu oluşturma
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        getData()
    }
    
    //ViewDidLoad sadece app ilk açıldığında başlatılır
    //ViewWillAppear VC'nin her çağırılmasında çalışır
    //Sayfa değişimi vb gibi
    //O nedenle Details VC'den gönderilen verileri sayfa değişiminde çağırmak için viewWillAppear kullanılır
    override func viewWillAppear(_ animated: Bool) {
        //Diğer taraftan haber verilen yeni verileri observer ile ulaşabilirsin
        //#selector kısmı: bu bilgi geldiğinde ne yapacağını bildirir fonk
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "veriGirildi"), object: nil)
    }
    
    //Kaydedilen verileri çekme fonksiyonu:
    //ViewDidLoad'Un altında da yapabilirdik fakat
    //Başka bir yerden de çekmek gerekirse diye ayrı fonk oluşturduk
    
    @objc func getData() {
        
        //Yeni bir ürün kaydedince eklenmiş ürünle beraber her seferinde tüm diziyi ekrana basıyor
        //Bütün eski ürünler defalarca ekrana yazılmasın diye aşağıdakini ekle
        isimDizisi.removeAll(keepingCapacity: false)
        idDizisi.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //verileri çekme isteği gönder
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MyNotes")
        
        //Bu alttaki satırı yapmasan da olur ama aklında bulunsun
        //çok büyük verilerle çalışırken caching mekanizmasından da faydalanabilmek için
        //bunu dalse yapabilrsin
        //Bu örnekte olmasa da olur
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let sonuclar = try context.fetch(fetchRequest)
            if sonuclar.count > 0 {
                //Sonuçlar bir Any Dizisi
                //Ama bunun NSManagedObject olmasını istiyoruz
                for sonuc in sonuclar as! [NSManagedObject] {
                    if let isim = sonuc.value(forKey: "name") as? String {
                        isimDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
                
                //Eğer verileri değiştiriyorsal tableView'daki verileri güncellemek için:
                // For looptan sonra yap
                tableView.reloadData()
            }
            
        } catch {
            print("Hata var")
        }
    }
    

    @objc func addButtonClicked (){
        secilenIsım = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.secilenUrunIsmi = secilenIsım
            destinationVC.secilenUrunId = secilenUUID
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenIsım = isimDizisi[indexPath.row]
        secilenUUID = idDizisi[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MyNotes")
            let uuidString = idDizisi[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let sonuclar = try context.fetch(fetchRequest)
                
                if sonuclar.count > 0 {
                    for sonuc in sonuclar as! [NSManagedObject] {
                        
                        if let id = sonuc.value(forKey: "id") as? UUID {
                            if id == idDizisi[indexPath.row]{
                                context.delete(sonuc)
                                isimDizisi.remove(at: indexPath.row)
                                idDizisi.remove(at: indexPath.row)
                                
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                                } catch {
                                    
                                }
                                break
                            }
                        }
                    }
                }
                
                
                
            } catch {
                print("Hata")
            }
        }
    }

}

