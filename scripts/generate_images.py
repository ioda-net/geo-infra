from generate_utils import Generate


class GenerateImages(Generate):
    '''Copy the images for one portal.

    It will fist copy the general images from src['img'] then the portal images from
    src['img_portal']. All the image will be copied in dest['img'].
    '''
    def generate(self):
        dest = self.dest['img']
        self.copy(self.src['img'], dest)
        self.copy(self.src['img_portal'], dest)
